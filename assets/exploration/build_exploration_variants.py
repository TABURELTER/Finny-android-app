"""
Finny Character Exploration Generator
Creates 3 distinct silhouette variants of Finny in Blender:
  - Variant A: Fox-Leaning (Sharp ears, elongated snout, massive bushy fox tail, energetic silhouette)
  - Variant B: Cat/Fox Hybrid (Plush/toy-like, round cheeks, tiny muzzle, huge eyes, soft puffy tail)
  - Variant C: Fantasy Companion (Whimsical ear shapes, layered leaf/flame hair crest, stylized stepped tail)

Sets up studio lighting, multi-angle cameras, individual renders, and side-by-side comparison sheets (Color & Black Silhouette).
"""

import bpy
import math
import os
import bmesh
from mathutils import Vector, Euler, Matrix

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if not bpy.data.scenes:
        bpy.data.scenes.new("Scene")

def create_material(name, base_color, roughness=0.5, specular=0.5, emission_color=(0,0,0,1), emission_strength=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    
    node_bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    node_bsdf.inputs['Base Color'].default_value = base_color
    node_bsdf.inputs['Roughness'].default_value = roughness
    if 'Specular IOR Level' in node_bsdf.inputs:
        node_bsdf.inputs['Specular IOR Level'].default_value = specular
    elif 'Specular' in node_bsdf.inputs:
        node_bsdf.inputs['Specular'].default_value = specular
        
    if 'Emission Color' in node_bsdf.inputs:
        node_bsdf.inputs['Emission Color'].default_value = emission_color
        node_bsdf.inputs['Emission Strength'].default_value = emission_strength
        
    node_output = nodes.new(type='ShaderNodeOutputMaterial')
    mat.node_tree.links.new(node_bsdf.outputs['BSDF'], node_output.inputs['Surface'])
    return mat

def create_eye_material(name, iris_color, pupil_color=(0.02, 0.02, 0.02, 1.0)):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    
    coord = nodes.new(type='ShaderNodeTexCoord')
    mapping = nodes.new(type='ShaderNodeMapping')
    grad = nodes.new(type='ShaderNodeTexGradient')
    grad.gradient_type = 'SPHERICAL'
    
    ramp = nodes.new(type='ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].position = 0.25
    ramp.color_ramp.elements[0].color = pupil_color
    ramp.color_ramp.elements[1].position = 0.55
    ramp.color_ramp.elements[1].color = iris_color
    
    elem3 = ramp.color_ramp.elements.new(0.85)
    elem3.color = (0.35, 0.95, 0.45, 1.0) # Vibrant green ring
    
    node_bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    node_bsdf.inputs['Roughness'].default_value = 0.1 # glossy cornea
    if 'Specular IOR Level' in node_bsdf.inputs:
        node_bsdf.inputs['Specular IOR Level'].default_value = 0.8
        
    node_output = nodes.new(type='ShaderNodeOutputMaterial')
    
    mat.node_tree.links.new(coord.outputs['Object'], mapping.inputs['Vector'])
    mat.node_tree.links.new(mapping.outputs['Vector'], grad.inputs['Vector'])
    mat.node_tree.links.new(grad.outputs['Fac'], ramp.inputs['Fac'])
    mat.node_tree.links.new(ramp.outputs['Color'], node_bsdf.inputs['Base Color'])
    mat.node_tree.links.new(node_bsdf.outputs['BSDF'], node_output.inputs['Surface'])
    return mat

def create_silhouette_material():
    mat = bpy.data.materials.new(name="Mat_Silhouette_Black")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    node_emit = nodes.new(type='ShaderNodeEmission')
    node_emit.inputs['Color'].default_value = (0.0, 0.0, 0.0, 1.0)
    node_emit.inputs['Strength'].default_value = 1.0
    node_output = nodes.new(type='ShaderNodeOutputMaterial')
    mat.node_tree.links.new(node_emit.outputs['Emission'], node_output.inputs['Surface'])
    return mat

def add_mesh_object(name, bmesh_data, collection, material=None, location=(0,0,0), scale=(1,1,1), rotation=(0,0,0)):
    mesh = bpy.data.meshes.new(name + "_mesh")
    bmesh_data.to_mesh(mesh)
    bmesh_data.free()
    
    obj = bpy.data.objects.new(name, mesh)
    obj.location = location
    obj.scale = scale
    obj.rotation_euler = rotation
    collection.objects.link(obj)
    
    if material:
        obj.data.materials.append(material)
        
    for poly in obj.data.polygons:
        poly.use_smooth = True
        
    return obj

def create_uv_sphere_bm(radius=1.0, segments=24, rings=16):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=radius)
    return bm

def create_cone_bm(radius1=1.0, radius2=0.0, depth=2.0, cap_ends=True, segments=20):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=cap_ends, segments=segments, radius1=radius1, radius2=radius2, depth=depth)
    return bm

def create_cylinder_bm(radius=1.0, depth=2.0, cap_ends=True, segments=20):
    bm = bmesh.new()
    bmesh.ops.create_cylinder(bm, cap_ends=cap_ends, segments=segments, radius=radius, depth=depth)
    return bm

def build_finny_character(variant_type, offset_x=0.0, collection=None, materials=None):
    if collection is None:
        collection = bpy.context.scene.collection
        
    var_coll = bpy.data.collections.new(f"Finny_Variant_{variant_type}")
    collection.children.link(var_coll)
    
    m_purple = materials["purple"]
    m_lime = materials["lime"]
    m_cream = materials["cream"]
    m_teal = materials["teal"]
    m_shorts = materials["shorts"]
    m_nose = materials["nose"]
    m_eye = materials["eye"]
    m_eye_white = materials["eye_white"]
    m_highlight = materials["highlight"]
    
    root_loc = Vector((offset_x, 0, 0))
    
    # -------------------------------------------------------------
    # 1. HEAD & FACE
    # -------------------------------------------------------------
    if variant_type == 'A': # FOX-LEANING
        bm_head = create_uv_sphere_bm(radius=0.58, segments=28, rings=20)
        for v in bm_head.verts:
            if v.co.y < 0:
                v.co.y *= 1.15
            if v.co.z > 0:
                v.co.x *= 0.95
        add_mesh_object("Head", bm_head, var_coll, m_purple, location=root_loc + Vector((0, 0, 1.45)), scale=(1.05, 0.95, 1.0))
        
        # Sharp angled cheek fur
        for side, x_sgn in [("L", 1), ("R", -1)]:
            bm_cheek = create_cone_bm(radius1=0.22, radius2=0.02, depth=0.55, segments=12)
            add_mesh_object(f"CheekTuft_{side}", bm_cheek, var_coll, m_purple,
                            location=root_loc + Vector((x_sgn * 0.58, -0.05, 1.35)),
                            scale=(1.0, 0.6, 1.0),
                            rotation=(math.radians(20), math.radians(x_sgn * -75), math.radians(x_sgn * 20)))
            bm_cheek2 = create_cone_bm(radius1=0.15, radius2=0.02, depth=0.45, segments=12)
            add_mesh_object(f"CheekTuft2_{side}", bm_cheek2, var_coll, m_purple,
                            location=root_loc + Vector((x_sgn * 0.52, -0.08, 1.22)),
                            scale=(1.0, 0.5, 1.0),
                            rotation=(math.radians(10), math.radians(x_sgn * -85), math.radians(x_sgn * 30)))
            
        # Elongated, sleek fox muzzle
        bm_snout = create_uv_sphere_bm(radius=0.28, segments=24, rings=16)
        for v in bm_snout.verts:
            if v.co.y < 0:
                v.co.y *= 1.55
                v.co.x *= 0.75
                v.co.z *= 0.8
        add_mesh_object("Muzzle", bm_snout, var_coll, m_cream,
                        location=root_loc + Vector((0, -0.42, 1.36)),
                        scale=(0.95, 1.25, 0.75))
        
        # Triangular fox nose
        bm_nose = create_cone_bm(radius1=0.065, radius2=0.01, depth=0.08, segments=10)
        add_mesh_object("Nose", bm_nose, var_coll, m_nose,
                        location=root_loc + Vector((0, -0.78, 1.40)),
                        rotation=(math.radians(90), 0, 0))
        
        # Tall sharp alert ears
        for side, x_sgn in [("L", 1), ("R", -1)]:
            bm_ear = create_cone_bm(radius1=0.28, radius2=0.04, depth=0.75, segments=16)
            for v in bm_ear.verts:
                v.co.x *= 0.7
            add_mesh_object(f"EarOuter_{side}", bm_ear, var_coll, m_purple,
                            location=root_loc + Vector((x_sgn * 0.42, 0.05, 2.05)),
                            rotation=(math.radians(-12), math.radians(x_sgn * -24), math.radians(x_sgn * 15)))
            
            bm_ear_inner = create_cone_bm(radius1=0.20, radius2=0.03, depth=0.55, segments=12)
            for v in bm_ear_inner.verts:
                v.co.x *= 0.6
            add_mesh_object(f"EarInner_{side}", bm_ear_inner, var_coll, m_cream,
                            location=root_loc + Vector((x_sgn * 0.40, -0.06, 2.02)),
                            rotation=(math.radians(-12), math.radians(x_sgn * -24), math.radians(x_sgn * 15)))
            
            bm_ear_tip = create_cone_bm(radius1=0.10, radius2=0.02, depth=0.26, segments=12)
            add_mesh_object(f"EarTip_{side}", bm_ear_tip, var_coll, m_lime,
                            location=root_loc + Vector((x_sgn * 0.50, 0.08, 2.36)),
                            rotation=(math.radians(-12), math.radians(x_sgn * -24), math.radians(x_sgn * 15)))
            
        # Spiked aerodynamic hair crest
        for i, (z_off, y_off, pitch) in enumerate([(0, 0, -10), (0.1, 0.06, 5), (-0.08, -0.05, -25)]):
            bm_tuft = create_cone_bm(radius1=0.14 - i*0.02, radius2=0.02, depth=0.45 - i*0.06, segments=10)
            add_mesh_object(f"HairSpike_{i}", bm_tuft, var_coll, m_lime,
                            location=root_loc + Vector((0, -0.08 + y_off, 2.05 + z_off)),
                            rotation=(math.radians(pitch), 0, 0))

    elif variant_type == 'B': # CAT/FOX HYBRID (PLUSH / TOY)
        bm_head = create_uv_sphere_bm(radius=0.62, segments=28, rings=20)
        for v in bm_head.verts:
            if v.co.z < 0.1:
                v.co.x *= 1.15
        add_mesh_object("Head", bm_head, var_coll, m_purple, location=root_loc + Vector((0, 0, 1.40)), scale=(1.12, 1.0, 0.95))
        
        # Soft chubby cheek puffs
        for side, x_sgn in [("L", 1), ("R", -1)]:
            bm_cheek = create_uv_sphere_bm(radius=0.26, segments=16, rings=12)
            add_mesh_object(f"CheekPuff_{side}", bm_cheek, var_coll, m_purple,
                            location=root_loc + Vector((x_sgn * 0.55, -0.15, 1.30)),
                            scale=(1.1, 0.8, 0.9))
            
        # Short button snout
        bm_snout = create_uv_sphere_bm(radius=0.25, segments=24, rings=16)
        add_mesh_object("Muzzle", bm_snout, var_coll, m_cream,
                        location=root_loc + Vector((0, -0.44, 1.30)),
                        scale=(1.25, 0.85, 0.85))
        
        # Button nose
        bm_nose = create_uv_sphere_bm(radius=0.06, segments=14, rings=10)
        add_mesh_object("Nose", bm_nose, var_coll, m_nose,
                        location=root_loc + Vector((0, -0.64, 1.34)),
                        scale=(1.2, 0.8, 0.9))
        
        # Soft rounded ears
        for side, x_sgn in [("L", 1), ("R", -1)]:
            bm_ear = create_cone_bm(radius1=0.30, radius2=0.08, depth=0.55, segments=16)
            for v in bm_ear.verts:
                v.co.x *= 0.8
            add_mesh_object(f"EarOuter_{side}", bm_ear, var_coll, m_purple,
                            location=root_loc + Vector((x_sgn * 0.44, 0.0, 1.95)),
                            rotation=(math.radians(-5), math.radians(x_sgn * -28), math.radians(x_sgn * 10)))
            
            bm_ear_inner = create_uv_sphere_bm(radius=0.18, segments=14, rings=10)
            add_mesh_object(f"EarInnerPuff_{side}", bm_ear_inner, var_coll, m_cream,
                            location=root_loc + Vector((x_sgn * 0.40, -0.08, 1.88)),
                            scale=(0.8, 0.5, 1.2))
            
            bm_ear_tip = create_uv_sphere_bm(radius=0.11, segments=12, rings=8)
            add_mesh_object(f"EarTip_{side}", bm_ear_tip, var_coll, m_lime,
                            location=root_loc + Vector((x_sgn * 0.53, 0.02, 2.18)),
                            scale=(0.9, 0.7, 1.1))
            
        # Puffy round cloud pompadour
        bm_tuft1 = create_uv_sphere_bm(radius=0.18, segments=16, rings=12)
        add_mesh_object("HairCloud_Main", bm_tuft1, var_coll, m_lime, location=root_loc + Vector((0, -0.15, 1.98)), scale=(1.2, 1.0, 1.1))
        bm_tuft2 = create_uv_sphere_bm(radius=0.13, segments=14, rings=10)
        add_mesh_object("HairCloud_SubL", bm_tuft2, var_coll, m_lime, location=root_loc + Vector((0.12, -0.12, 1.95)))
        bm_tuft3 = create_uv_sphere_bm(radius=0.12, segments=14, rings=10)
        add_mesh_object("HairCloud_SubR", bm_tuft3, var_coll, m_lime, location=root_loc + Vector((-0.12, -0.12, 1.95)))

    else: # VARIANT C: FANTASY COMPANION
        bm_head = create_uv_sphere_bm(radius=0.59, segments=28, rings=20)
        for v in bm_head.verts:
            if v.co.z > 0.2:
                v.co.y *= 0.95
        add_mesh_object("Head", bm_head, var_coll, m_purple, location=root_loc + Vector((0, 0, 1.45)), scale=(1.04, 0.98, 1.02))
        
        # Dual-tier fantasy cheek flares
        for side, x_sgn in [("L", 1), ("R", -1)]:
            bm_flare1 = create_cone_bm(radius1=0.18, radius2=0.02, depth=0.58, segments=12)
            add_mesh_object(f"CheekFlareUpper_{side}", bm_flare1, var_coll, m_purple,
                            location=root_loc + Vector((x_sgn * 0.58, -0.06, 1.42)),
                            scale=(1.0, 0.5, 0.8),
                            rotation=(math.radians(-10), math.radians(x_sgn * -70), math.radians(x_sgn * 15)))
            bm_flare2 = create_cone_bm(radius1=0.14, radius2=0.02, depth=0.46, segments=12)
            add_mesh_object(f"CheekFlareLower_{side}", bm_flare2, var_coll, m_lime,
                            location=root_loc + Vector((x_sgn * 0.54, -0.08, 1.26)),
                            scale=(0.9, 0.5, 0.7),
                            rotation=(math.radians(15), math.radians(x_sgn * -80), math.radians(x_sgn * 35)))
            
        # Refined stylized fantasy muzzle
        bm_snout = create_uv_sphere_bm(radius=0.26, segments=24, rings=16)
        for v in bm_snout.verts:
            if v.co.y < 0:
                v.co.y *= 1.3
        add_mesh_object("Muzzle", bm_snout, var_coll, m_cream,
                        location=root_loc + Vector((0, -0.42, 1.34)),
                        scale=(1.05, 1.05, 0.82))
        
        # Heart-styled soft dark nose
        bm_nose = create_uv_sphere_bm(radius=0.065, segments=14, rings=10)
        add_mesh_object("Nose", bm_nose, var_coll, m_nose,
                        location=root_loc + Vector((0, -0.72, 1.38)),
                        scale=(1.1, 0.7, 0.9))
        
        # Fantasy Lynx/Fennec Ears with outer notch & feathered tips
        for side, x_sgn in [("L", 1), ("R", -1)]:
            bm_ear = create_cone_bm(radius1=0.29, radius2=0.03, depth=0.82, segments=16)
            for v in bm_ear.verts:
                v.co.x *= 0.68
                if v.co.z > 0:
                    v.co.x += (v.co.z ** 1.5) * 0.15
            add_mesh_object(f"EarOuter_{side}", bm_ear, var_coll, m_purple,
                            location=root_loc + Vector((x_sgn * 0.44, 0.04, 2.08)),
                            rotation=(math.radians(-10), math.radians(x_sgn * -22), math.radians(x_sgn * 12)))
            
            bm_ear_inner = create_cone_bm(radius1=0.18, radius2=0.02, depth=0.60, segments=12)
            add_mesh_object(f"EarInner_{side}", bm_ear_inner, var_coll, m_cream,
                            location=root_loc + Vector((x_sgn * 0.41, -0.06, 2.05)),
                            rotation=(math.radians(-10), math.radians(x_sgn * -22), math.radians(x_sgn * 12)))
            
            bm_feather = create_cone_bm(radius1=0.08, radius2=0.01, depth=0.36, segments=10)
            add_mesh_object(f"EarFeather_{side}", bm_feather, var_coll, m_lime,
                            location=root_loc + Vector((x_sgn * 0.52, 0.08, 2.45)),
                            rotation=(math.radians(-25), math.radians(x_sgn * -40), math.radians(x_sgn * 25)))
            
        # Fantasy Layered Leaf/Flame Crest
        crest_configs = [
            (0, -0.12, 2.08, 0.15, 0.52, -18, 0),
            (0.12, -0.08, 2.04, 0.11, 0.42, -8, 15),
            (-0.12, -0.08, 2.04, 0.11, 0.42, -8, -15),
            (0, 0.02, 2.14, 0.13, 0.48, 8, 0)
        ]
        for idx, (cx, cy, cz, cr, cd, cp, cyaw) in enumerate(crest_configs):
            bm_crest = create_cone_bm(radius1=cr, radius2=0.02, depth=cd, segments=10)
            add_mesh_object(f"HairCrest_{idx}", bm_crest, var_coll, m_lime,
                            location=root_loc + Vector((cx, cy, cz)),
                            rotation=(math.radians(cp), math.radians(cyaw), 0))

    # -------------------------------------------------------------
    # 2. EYES
    # -------------------------------------------------------------
    eye_scale = Vector((0.18, 0.14, 0.20))
    eye_y = -0.46
    eye_z = 1.48
    eye_x_spacing = 0.28
    
    if variant_type == 'A':
        eye_scale = Vector((0.17, 0.14, 0.20))
        eye_x_spacing = 0.30
    elif variant_type == 'B':
        eye_scale = Vector((0.22, 0.17, 0.23))
        eye_x_spacing = 0.31
        eye_z = 1.44
    else: # C
        eye_scale = Vector((0.19, 0.15, 0.21))
        eye_x_spacing = 0.29
        
    for side, x_sgn in [("L", 1), ("R", -1)]:
        bm_ew = create_uv_sphere_bm(radius=1.0, segments=20, rings=16)
        add_mesh_object(f"EyeWhite_{side}", bm_ew, var_coll, m_eye_white,
                        location=root_loc + Vector((x_sgn * eye_x_spacing, eye_y, eye_z)),
                        scale=eye_scale,
                        rotation=(0, math.radians(x_sgn * -8), 0))
        
        bm_iris = create_uv_sphere_bm(radius=1.0, segments=20, rings=16)
        add_mesh_object(f"Iris_{side}", bm_iris, var_coll, m_eye,
                        location=root_loc + Vector((x_sgn * eye_x_spacing, eye_y - 0.05, eye_z)),
                        scale=eye_scale * 0.88,
                        rotation=(math.radians(90), 0, 0))
        
        bm_h1 = create_uv_sphere_bm(radius=0.045, segments=12, rings=8)
        add_mesh_object(f"Highlight1_{side}", bm_h1, var_coll, m_highlight,
                        location=root_loc + Vector((x_sgn * eye_x_spacing - 0.04, eye_y - 0.16, eye_z + 0.06)))
        bm_h2 = create_uv_sphere_bm(radius=0.024, segments=10, rings=6)
        add_mesh_object(f"Highlight2_{side}", bm_h2, var_coll, m_highlight,
                        location=root_loc + Vector((x_sgn * eye_x_spacing + 0.04, eye_y - 0.15, eye_z - 0.05)))
        
        bm_brow = create_cylinder_bm(radius=0.035, depth=0.22, segments=10)
        brow_pitch = 10 if variant_type == 'B' else (5 if variant_type == 'C' else 15)
        add_mesh_object(f"Eyebrow_{side}", bm_brow, var_coll, m_purple,
                        location=root_loc + Vector((x_sgn * eye_x_spacing, eye_y - 0.08, eye_z + 0.22)),
                        rotation=(math.radians(10), math.radians(x_sgn * brow_pitch), math.radians(x_sgn * -15)))

    # -------------------------------------------------------------
    # 3. BODY & TEAL HOODIE
    # -------------------------------------------------------------
    if variant_type == 'A':
        bm_torso = create_cylinder_bm(radius=0.32, depth=0.75, segments=20)
        add_mesh_object("Hoodie", bm_torso, var_coll, m_teal,
                        location=root_loc + Vector((0, 0, 0.85)), scale=(1.05, 0.85, 1.0))
        bm_shorts = create_cylinder_bm(radius=0.33, depth=0.30, segments=20)
        add_mesh_object("Shorts", bm_shorts, var_coll, m_shorts,
                        location=root_loc + Vector((0, 0, 0.46)), scale=(1.02, 0.88, 1.0))
    elif variant_type == 'B':
        bm_torso = create_uv_sphere_bm(radius=0.44, segments=24, rings=16)
        add_mesh_object("Hoodie", bm_torso, var_coll, m_teal,
                        location=root_loc + Vector((0, 0, 0.80)), scale=(1.15, 0.95, 0.95))
        bm_shorts = create_cylinder_bm(radius=0.36, depth=0.24, segments=20)
        add_mesh_object("Shorts", bm_shorts, var_coll, m_shorts,
                        location=root_loc + Vector((0, 0, 0.44)), scale=(1.1, 0.95, 1.0))
    else:
        bm_torso = create_cylinder_bm(radius=0.34, depth=0.72, segments=20)
        add_mesh_object("Hoodie", bm_torso, var_coll, m_teal,
                        location=root_loc + Vector((0, 0, 0.83)), scale=(1.02, 0.86, 1.0))
        bm_shorts = create_cylinder_bm(radius=0.34, depth=0.28, segments=20)
        add_mesh_object("Shorts", bm_shorts, var_coll, m_shorts,
                        location=root_loc + Vector((0, 0, 0.46)), scale=(1.02, 0.88, 1.0))

    # Hood fold at back
    bm_hood_back = create_uv_sphere_bm(radius=0.32, segments=18, rings=12)
    add_mesh_object("HoodFold", bm_hood_back, var_coll, m_teal,
                    location=root_loc + Vector((0, 0.22, 1.10)), scale=(1.1, 0.65, 0.7))
    
    # Paw Print Emblem on chest
    bm_paw_center = create_cylinder_bm(radius=0.065, depth=0.02, segments=14)
    add_mesh_object("PawEmblem_Center", bm_paw_center, var_coll, m_cream,
                    location=root_loc + Vector((0, -0.32, 0.88)), rotation=(math.radians(85), 0, 0))
    for p_x, p_z in [(-0.05, 0.96), (0.0, 0.98), (0.05, 0.96)]:
        bm_toe = create_cylinder_bm(radius=0.022, depth=0.02, segments=10)
        add_mesh_object(f"PawToe_{p_x}", bm_toe, var_coll, m_cream,
                        location=root_loc + Vector((p_x, -0.32, p_z)), rotation=(math.radians(85), 0, 0))

    # -------------------------------------------------------------
    # 4. LIMBS
    # -------------------------------------------------------------
    leg_len = 0.40 if variant_type == 'A' else (0.30 if variant_type == 'B' else 0.36)
    for side, x_sgn in [("L", 1), ("R", -1)]:
        bm_sleeve = create_cylinder_bm(radius=0.12, depth=0.30, segments=14)
        add_mesh_object(f"Sleeve_{side}", bm_sleeve, var_coll, m_teal,
                        location=root_loc + Vector((x_sgn * 0.42, 0, 0.88)),
                        rotation=(0, 0, math.radians(x_sgn * -22)))
        
        bm_arm = create_cylinder_bm(radius=0.095, depth=0.32, segments=14)
        add_mesh_object(f"Arm_{side}", bm_arm, var_coll, m_purple,
                        location=root_loc + Vector((x_sgn * 0.52, 0, 0.66)),
                        rotation=(0, 0, math.radians(x_sgn * -15)))
        
        bm_hand = create_uv_sphere_bm(radius=0.13, segments=16, rings=12)
        add_mesh_object(f"Hand_{side}", bm_hand, var_coll, m_cream,
                        location=root_loc + Vector((x_sgn * 0.58, -0.02, 0.48)),
                        scale=(1.0, 1.15, 0.9))
        
        bm_leg = create_cylinder_bm(radius=0.11, depth=leg_len, segments=14)
        add_mesh_object(f"Leg_{side}", bm_leg, var_coll, m_purple,
                        location=root_loc + Vector((x_sgn * 0.20, 0, 0.24)))
        
        bm_foot = create_uv_sphere_bm(radius=0.15, segments=16, rings=12)
        add_mesh_object(f"Foot_{side}", bm_foot, var_coll, m_cream,
                        location=root_loc + Vector((x_sgn * 0.20, -0.08, 0.08)),
                        scale=(0.95, 1.45, 0.65))

    # -------------------------------------------------------------
    # 5. TAIL
    # -------------------------------------------------------------
    if variant_type == 'A': # Huge sweeping upward fox tail with sharp lime tip
        tail_segments = [
            (Vector((0, 0.32, 0.45)), 0.16, 0.42, -35, 0, m_purple),
            (Vector((0, 0.56, 0.65)), 0.26, 0.52, -55, 10, m_purple),
            (Vector((0, 0.72, 0.96)), 0.34, 0.60, -75, 15, m_purple),
            (Vector((0, 0.68, 1.34)), 0.32, 0.54, -95, 10, m_purple),
            (Vector((0, 0.48, 1.62)), 0.22, 0.48, -125, 0, m_lime),
            (Vector((0, 0.26, 1.76)), 0.10, 0.32, -145, 0, m_lime)
        ]
        for i, (tloc, trad, tlen, tpitch, troll, tmat) in enumerate(tail_segments):
            bm_t = create_cone_bm(radius1=trad, radius2=trad*0.75, depth=tlen, segments=16)
            add_mesh_object(f"FoxTail_Seg_{i}", bm_t, var_coll, tmat,
                            location=root_loc + tloc,
                            rotation=(math.radians(tpitch), 0, math.radians(troll)))

    elif variant_type == 'B': # Plump, pillow-soft, rounded cloud tail
        tail_segments = [
            (Vector((0, 0.28, 0.42)), 0.18, 0.36, -20, 0, m_purple),
            (Vector((0, 0.48, 0.54)), 0.28, 0.46, -40, 5, m_purple),
            (Vector((0, 0.68, 0.74)), 0.35, 0.50, -60, 10, m_purple),
            (Vector((0, 0.74, 1.02)), 0.34, 0.48, -80, 5, m_purple),
            (Vector((0, 0.62, 1.28)), 0.28, 0.42, -105, 0, m_lime),
            (Vector((0, 0.45, 1.42)), 0.18, 0.30, -125, 0, m_lime)
        ]
        for i, (tloc, trad, tlen, tpitch, troll, tmat) in enumerate(tail_segments):
            bm_t = create_uv_sphere_bm(radius=trad, segments=16, rings=12)
            add_mesh_object(f"PlushTail_Seg_{i}", bm_t, var_coll, tmat,
                            location=root_loc + tloc,
                            scale=(1.05, 1.25, 1.05))

    else: # Whimsical flame/feather curved tail with stepped lime fins
        tail_segments = [
            (Vector((0, 0.30, 0.44)), 0.16, 0.38, -30, 0, m_purple),
            (Vector((0, 0.54, 0.62)), 0.25, 0.48, -50, 8, m_purple),
            (Vector((0, 0.70, 0.90)), 0.33, 0.55, -70, 15, m_purple),
            (Vector((0, 0.65, 1.24)), 0.30, 0.50, -95, 12, m_purple),
            (Vector((0, 0.46, 1.50)), 0.22, 0.45, -120, 5, m_lime),
            (Vector((0, 0.24, 1.65)), 0.12, 0.35, -145, 0, m_lime)
        ]
        for i, (tloc, trad, tlen, tpitch, troll, tmat) in enumerate(tail_segments):
            bm_t = create_cone_bm(radius1=trad, radius2=trad*0.65, depth=tlen, segments=16)
            add_mesh_object(f"FantasyTail_Seg_{i}", bm_t, var_coll, tmat,
                            location=root_loc + tloc,
                            rotation=(math.radians(tpitch), 0, math.radians(troll)))
        for f_i, (floc, frot, fscl) in enumerate([
            (Vector((0.15, 0.72, 0.98)), (math.radians(-60), math.radians(25), math.radians(35)), 0.22),
            (Vector((-0.15, 0.68, 1.15)), (math.radians(-80), math.radians(-25), math.radians(-35)), 0.20),
            (Vector((0.12, 0.48, 1.45)), (math.radians(-110), math.radians(20), math.radians(25)), 0.18)
        ]):
            bm_tf = create_cone_bm(radius1=fscl*0.6, radius2=0.01, depth=fscl*2.2, segments=10)
            add_mesh_object(f"TailFeather_{f_i}", bm_tf, var_coll, m_lime,
                            location=root_loc + floc, rotation=frot)

    return var_coll

def setup_studio_environment():
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE_NEXT' if 'BLENDER_EEVEE_NEXT' in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items else 'BLENDER_EEVEE'
    
    world = bpy.data.worlds.new("StudioWorld")
    scene.world = world
    world.use_nodes = True
    bg_node = world.node_tree.nodes['Background']
    bg_node.inputs['Color'].default_value = (0.93, 0.93, 0.95, 1.0)
    bg_node.inputs['Strength'].default_value = 0.85
    
    bm_plane = bmesh.new()
    bmesh.ops.create_grid(bm_plane, x_segments=2, y_segments=2, size=20.0)
    m_ground = create_material("Mat_StudioFloor", (0.88, 0.88, 0.91, 1.0), roughness=0.6)
    add_mesh_object("StudioFloor", bm_plane, scene.collection, m_ground, location=(0,0,-0.02))
    
    light_coll = bpy.data.collections.new("Studio_Lights")
    scene.collection.children.link(light_coll)
    
    # Key Light (Warm soft studio area light)
    light_key_data = bpy.data.lights.new(name="Light_Key", type='AREA')
    light_key_data.energy = 550.0
    light_key_data.size = 4.0
    light_key_data.color = (1.0, 0.97, 0.93)
    key_obj = bpy.data.objects.new("Light_Key", light_key_data)
    key_obj.location = (-3.0, -4.5, 4.0)
    key_obj.rotation_euler = (math.radians(50), math.radians(0), math.radians(-30))
    light_coll.objects.link(key_obj)
    
    # Fill Light (Cool soft fill)
    light_fill_data = bpy.data.lights.new(name="Light_Fill", type='AREA')
    light_fill_data.energy = 220.0
    light_fill_data.size = 5.0
    light_fill_data.color = (0.88, 0.94, 1.0)
    fill_obj = bpy.data.objects.new("Light_Fill", light_fill_data)
    fill_obj.location = (3.8, -3.5, 3.0)
    fill_obj.rotation_euler = (math.radians(55), math.radians(0), math.radians(40))
    light_coll.objects.link(fill_obj)
    
    # Rim / Kicker Light
    light_rim_data = bpy.data.lights.new(name="Light_Rim", type='SPOT')
    light_rim_data.energy = 750.0
    light_rim_data.spot_size = math.radians(80)
    light_rim_data.color = (0.95, 1.0, 0.90)
    rim_obj = bpy.data.objects.new("Light_Rim", light_rim_data)
    rim_obj.location = (0.0, 4.5, 4.2)
    rim_obj.rotation_euler = (math.radians(-50), 0, math.radians(180))
    light_coll.objects.link(rim_obj)

def main():
    clear_scene()
    print("Initializing Finny Exploration Scene...")
    
    materials = {
        "purple": create_material("Mat_Fur_Purple", (0.46, 0.26, 0.61, 1.0), roughness=0.6),
        "lime": create_material("Mat_Fur_Lime", (0.54, 0.88, 0.17, 1.0), roughness=0.5),
        "cream": create_material("Mat_Cream", (0.97, 0.91, 0.83, 1.0), roughness=0.55),
        "teal": create_material("Mat_Teal_Hoodie", (0.18, 0.64, 0.66, 1.0), roughness=0.5),
        "shorts": create_material("Mat_Shorts", (0.49, 0.38, 0.30, 1.0), roughness=0.6),
        "nose": create_material("Mat_Nose_Dark", (0.17, 0.11, 0.22, 1.0), roughness=0.35),
        "eye": create_eye_material("Mat_Eye_Emerald", (0.05, 0.82, 0.32, 1.0)),
        "eye_white": create_material("Mat_Eye_White", (0.96, 0.96, 0.96, 1.0), roughness=0.1),
        "highlight": create_material("Mat_Highlight", (1.0, 1.0, 1.0, 1.0), emission_color=(1,1,1,1), emission_strength=1.5)
    }
    create_silhouette_material()
    
    setup_studio_environment()
    
    # Build the 3 Variants side-by-side:
    # A at X = -2.3, B at X = 0.0, C at X = +2.3
    coll_a = build_finny_character('A', offset_x=-2.3, materials=materials)
    coll_b = build_finny_character('B', offset_x=0.0, materials=materials)
    coll_c = build_finny_character('C', offset_x=2.3, materials=materials)
    
    blend_path = "d:/Finny/assets/exploration/finny_exploration.blend"
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f"Scene successfully saved to {blend_path}")

if __name__ == "__main__":
    main()
