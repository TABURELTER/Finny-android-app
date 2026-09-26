"""
Finny Character Exploration - Definitive Stylized 3D Generator & Renderer
Creates 3 distinct, high-appeal silhouette variants:
  - Variant A: Fox-Leaning (Sleek snout, sharp triangular ears, energetic crest, massive sweeping fox tail)
  - Variant B: Cat/Fox Hybrid (Plush/toy-like, round cheeks, tiny muzzle, huge eyes, soft cloud tail)
  - Variant C: Fantasy Companion (Whimsical notched ears with feather tips, layered flame crest, stepped fins tail)

Features:
  - High-appeal stylized cartoon face matching concept art (large emerald eyes, dark upper liner, double glints, cream muzzle, cute nose & smile, pink blush)
  - Integrated, continuous ear geometry with seamlessly attached lime tips
  - Volumetric, smoothly curving expressive tails arching to the side for readable silhouettes
  - Full-body and close-up camera setups with comfortable framing margins
  - Side-by-side comparison sheets (Color & Pure Black Silhouette)
"""

import bpy
import math
import os
import bmesh
from mathutils import Vector, Euler, Matrix

def srgb_to_linear(c):
    return [pow(x, 2.2) for x in c[:3]] + ([c[3]] if len(c) > 3 else [1.0])

def clear_all():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for coll in list(bpy.data.collections):
        bpy.data.collections.remove(coll)
    for mat in list(bpy.data.materials):
        bpy.data.materials.remove(mat)
    for cam in list(bpy.data.cameras):
        bpy.data.cameras.remove(cam)
    for light in list(bpy.data.lights):
        bpy.data.lights.remove(light)

def create_pbr_material(name, srgb_color, roughness=0.50, specular=0.5, emission_srgb=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name=name)
    nodes = mat.node_tree.nodes
    nodes.clear()
    
    lin_color = srgb_to_linear(srgb_color)
    node_bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    node_bsdf.inputs['Base Color'].default_value = lin_color
    node_bsdf.inputs['Roughness'].default_value = roughness
    
    if 'Specular IOR Level' in node_bsdf.inputs:
        node_bsdf.inputs['Specular IOR Level'].default_value = specular
    elif 'Specular' in node_bsdf.inputs:
        node_bsdf.inputs['Specular'].default_value = specular
        
    if emission_srgb and emission_strength > 0:
        lin_emit = srgb_to_linear(emission_srgb)
        if 'Emission Color' in node_bsdf.inputs:
            node_bsdf.inputs['Emission Color'].default_value = lin_emit
            node_bsdf.inputs['Emission Strength'].default_value = emission_strength
            
    node_output = nodes.new(type='ShaderNodeOutputMaterial')
    mat.node_tree.links.new(node_bsdf.outputs['BSDF'], node_output.inputs['Surface'])
    return mat

def create_silhouette_material():
    mat = bpy.data.materials.new(name="Mat_Silhouette_Black")
    nodes = mat.node_tree.nodes
    nodes.clear()
    node_emit = nodes.new(type='ShaderNodeEmission')
    node_emit.inputs['Color'].default_value = (0.0, 0.0, 0.0, 1.0)
    node_emit.inputs['Strength'].default_value = 1.0
    node_output = nodes.new(type='ShaderNodeOutputMaterial')
    mat.node_tree.links.new(node_emit.outputs['Emission'], node_output.inputs['Surface'])
    return mat

def add_mesh(name, bmesh_data, collection, material=None, location=(0,0,0), scale=(1,1,1), rotation=(0,0,0), subdiv=False):
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
        
    if subdiv:
        mod = obj.modifiers.new(name="Subdiv", type='SUBSURF')
        mod.levels = 1
        mod.render_levels = 1
        
    return obj

def create_sphere(radius=1.0, u=32, v=24):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=radius)
    return bm

def create_cone(r1=1.0, r2=0.0, depth=2.0, u=24):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=u, radius1=r1, radius2=r2, depth=depth)
    return bm

def create_cylinder(radius=1.0, depth=2.0, u=24):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=u, radius1=radius, radius2=radius, depth=depth)
    return bm

def create_smooth_tube(points, radii, u=16):
    """Generates a smooth lofted tube with caps along 3D centerline points and radii"""
    bm = bmesh.new()
    rings = []
    
    for idx, (pt, rad) in enumerate(zip(points, radii)):
        if idx == 0:
            tangent = (points[1] - pt).normalized()
        elif idx == len(points) - 1:
            tangent = (pt - points[-1]).normalized()
        else:
            tangent = (points[idx+1] - points[idx-1]).normalized()
            
        up = Vector((0, 0, 1)) if abs(tangent.z) < 0.88 else Vector((0, 1, 0))
        normal = tangent.cross(up).normalized()
        binormal = tangent.cross(normal).normalized()
        
        ring = []
        for i in range(u):
            ang = 2.0 * math.pi * i / u
            offset = (normal * math.cos(ang) + binormal * math.sin(ang)) * rad
            v = bm.verts.new(pt + offset)
            ring.append(v)
        rings.append(ring)
        
    for r in range(len(rings) - 1):
        for i in range(u):
            ni = (i + 1) % u
            bm.faces.new([rings[r][i], rings[r][ni], rings[r+1][ni], rings[r+1][i]])
            
    # Cap ends
    bm.faces.new(rings[0])
    bm.faces.new(list(reversed(rings[-1])))
    
    for p in bm.faces:
        p.smooth = True
        
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
    m_hood_trim = materials["hood_trim"]
    m_shorts = materials["shorts"]
    m_nose = materials["nose"]
    m_mouth = materials["mouth"]
    m_blush = materials["blush"]
    m_eye_white = materials["eye_white"]
    m_iris = materials["iris"]
    m_pupil = materials["pupil"]
    m_liner = materials["liner"]
    m_glint = materials["glint"]
    
    root = Vector((offset_x, 0, 0))
    
    # =========================================================================
    # 1. HEAD, CHEEKS & FACE
    # =========================================================================
    if variant_type == 'A': # FOX-LEANING
        # Head: Slightly elongated, sleek fox skull with alert posture
        bm_head = create_sphere(radius=0.54, u=36, v=28)
        for v in bm_head.verts:
            if v.co.y < 0:
                v.co.y *= 1.10
            if v.co.z > 0.1:
                v.co.x *= 0.94
        add_mesh(f"Head_{variant_type}", bm_head, var_coll, m_purple,
                 location=root + Vector((0, 0, 1.44)), scale=(1.04, 0.98, 1.02), subdiv=True)
        
        # Cheek Fur: Sharp, sleek, swept-back fox tufts
        for side, sgn in [("L", 1), ("R", -1)]:
            bm_c1 = create_cone(r1=0.20, r2=0.02, depth=0.55, u=16)
            add_mesh(f"CheekTuft1_{side}_{variant_type}", bm_c1, var_coll, m_purple,
                     location=root + Vector((sgn * 0.52, -0.06, 1.36)), scale=(1.0, 0.50, 0.95),
                     rotation=(math.radians(16), math.radians(sgn * -74), math.radians(sgn * 16)))
            bm_c2 = create_cone(r1=0.15, r2=0.02, depth=0.45, u=14)
            add_mesh(f"CheekTuft2_{side}_{variant_type}", bm_c2, var_coll, m_purple,
                     location=root + Vector((sgn * 0.48, -0.08, 1.25)), scale=(0.92, 0.45, 0.85),
                     rotation=(math.radians(8), math.radians(sgn * -86), math.radians(sgn * 26)))
            
        # Muzzle: Sleek, tapered fox snout with warm cream fur
        bm_snout = create_sphere(radius=0.25, u=32, v=24)
        for v in bm_snout.verts:
            if v.co.y < 0:
                v.co.y *= 1.45
                v.co.x *= 0.82
                v.co.z *= 0.78
        add_mesh(f"Muzzle_{variant_type}", bm_snout, var_coll, m_cream,
                 location=root + Vector((0, -0.34, 1.34)), scale=(1.0, 1.15, 0.80), subdiv=True)
        
        # Triangular dark nose on top bridge
        bm_nose = create_cone(r1=0.055, r2=0.012, depth=0.07, u=14)
        add_mesh(f"Nose_{variant_type}", bm_nose, var_coll, m_nose,
                 location=root + Vector((0, -0.66, 1.39)), rotation=(math.radians(85), 0, 0))
        
        # Friendly smile
        bm_mouth = create_cylinder(radius=0.015, depth=0.16, u=12)
        add_mesh(f"Mouth_{variant_type}", bm_mouth, var_coll, m_mouth,
                 location=root + Vector((0, -0.56, 1.27)), rotation=(0, math.radians(90), 0))
        
        # Fox Ears: Integrated tall sharp ears with inner cavity & lime tip
        for side, sgn in [("L", 1), ("R", -1)]:
            # Base outer ear
            bm_ear = create_cone(r1=0.26, r2=0.08, depth=0.55, u=18)
            for v in bm_ear.verts:
                v.co.x *= 0.65
            add_mesh(f"EarBase_{side}_{variant_type}", bm_ear, var_coll, m_purple,
                     location=root + Vector((sgn * 0.40, 0.04, 1.98)),
                     rotation=(math.radians(-10), math.radians(sgn * -22), math.radians(sgn * 14)))
            
            # Inner cream fluff
            bm_inner = create_cone(r1=0.18, r2=0.05, depth=0.45, u=14)
            for v in bm_inner.verts:
                v.co.x *= 0.52
            add_mesh(f"EarInner_{side}_{variant_type}", bm_inner, var_coll, m_cream,
                     location=root + Vector((sgn * 0.38, -0.04, 1.96)),
                     rotation=(math.radians(-10), math.radians(sgn * -22), math.radians(sgn * 14)))
            
            # Sharp Lime Ear Tip seamlessly attached
            bm_tip = create_cone(r1=0.085, r2=0.015, depth=0.30, u=14)
            for v in bm_tip.verts:
                v.co.x *= 0.65
            add_mesh(f"EarTip_{side}_{variant_type}", bm_tip, var_coll, m_lime,
                     location=root + Vector((sgn * 0.48, 0.07, 2.30)),
                     rotation=(math.radians(-10), math.radians(sgn * -22), math.radians(sgn * 14)))
            
        # Hair Tuft: Energetic 3-spike backward-swept lime crest
        for i, (z_off, y_off, pitch) in enumerate([(0, 0, -14), (0.09, 0.05, 4), (-0.07, -0.04, -28)]):
            bm_tuft = create_cone(r1=0.13 - i*0.02, r2=0.015, depth=0.44 - i*0.06, u=14)
            add_mesh(f"HairSpike_{i}_{variant_type}", bm_tuft, var_coll, m_lime,
                     location=root + Vector((0, -0.07 + y_off, 2.02 + z_off)),
                     rotation=(math.radians(pitch), 0, 0))

    elif variant_type == 'B': # CAT/FOX HYBRID (PLUSH / TOY-LIKE)
        # Head: Extra round, chubby plush cheeks, maximum baby/toy softness
        bm_head = create_sphere(radius=0.58, u=36, v=28)
        for v in bm_head.verts:
            if v.co.z < 0.12:
                v.co.x *= 1.15
        add_mesh(f"Head_{variant_type}", bm_head, var_coll, m_purple,
                 location=root + Vector((0, 0, 1.40)), scale=(1.10, 1.02, 0.96), subdiv=True)
        
        # Soft rounded cheek puffs
        for side, sgn in [("L", 1), ("R", -1)]:
            bm_c = create_sphere(radius=0.25, u=24, v=18)
            add_mesh(f"CheekPuff_{side}_{variant_type}", bm_c, var_coll, m_purple,
                     location=root + Vector((sgn * 0.52, -0.12, 1.30)), scale=(1.10, 0.85, 0.90))
            
        # Muzzle: Short, rounded baby button muzzle
        bm_snout = create_sphere(radius=0.24, u=28, v=22)
        add_mesh(f"Muzzle_{variant_type}", bm_snout, var_coll, m_cream,
                 location=root + Vector((0, -0.36, 1.30)), scale=(1.22, 0.85, 0.84), subdiv=True)
        
        # Round button nose
        bm_nose = create_sphere(radius=0.055, u=18, v=14)
        add_mesh(f"Nose_{variant_type}", bm_nose, var_coll, m_nose,
                 location=root + Vector((0, -0.54, 1.34)), scale=(1.2, 0.82, 0.88))
        
        # Sweet small smile
        bm_mouth = create_cylinder(radius=0.014, depth=0.14, u=10)
        add_mesh(f"Mouth_{variant_type}", bm_mouth, var_coll, m_mouth,
                 location=root + Vector((0, -0.48, 1.25)), rotation=(0, math.radians(90), 0))
        
        # Soft rounded cat/fox ears
        for side, sgn in [("L", 1), ("R", -1)]:
            bm_ear = create_cone(r1=0.28, r2=0.10, depth=0.45, u=20)
            for v in bm_ear.verts:
                v.co.x *= 0.80
            add_mesh(f"EarBase_{side}_{variant_type}", bm_ear, var_coll, m_purple,
                     location=root + Vector((sgn * 0.42, 0.0, 1.90)),
                     rotation=(math.radians(-5), math.radians(sgn * -26), math.radians(sgn * 8)))
            
            # Inner soft puff
            bm_inner = create_sphere(radius=0.17, u=18, v=14)
            add_mesh(f"EarInnerPuff_{side}_{variant_type}", bm_inner, var_coll, m_cream,
                     location=root + Vector((sgn * 0.39, -0.06, 1.86)), scale=(0.82, 0.50, 1.15))
            
            # Soft rounded lime cap
            bm_tip = create_sphere(radius=0.105, u=16, v=12)
            add_mesh(f"EarTip_{side}_{variant_type}", bm_tip, var_coll, m_lime,
                     location=root + Vector((sgn * 0.49, 0.02, 2.14)), scale=(0.92, 0.70, 1.10))
            
        # Puffy round cloud pompadour
        bm_tuft1 = create_sphere(radius=0.17, u=20, v=16)
        add_mesh(f"HairCloud_Main_{variant_type}", bm_tuft1, var_coll, m_lime,
                 location=root + Vector((0, -0.12, 1.94)), scale=(1.22, 1.02, 1.12))
        bm_tuft2 = create_sphere(radius=0.12, u=18, v=14)
        add_mesh(f"HairCloud_SubL_{variant_type}", bm_tuft2, var_coll, m_lime,
                 location=root + Vector((0.12, -0.10, 1.91)))
        bm_tuft3 = create_sphere(radius=0.11, u=18, v=14)
        add_mesh(f"HairCloud_SubR_{variant_type}", bm_tuft3, var_coll, m_lime,
                 location=root + Vector((-0.12, -0.10, 1.91)))

    else: # VARIANT C: FANTASY COMPANION
        # Head: Stylized teardrop skull with dual-tier cheek fluff
        bm_head = create_sphere(radius=0.56, u=36, v=28)
        for v in bm_head.verts:
            if v.co.z > 0.15:
                v.co.y *= 0.94
        add_mesh(f"Head_{variant_type}", bm_head, var_coll, m_purple,
                 location=root + Vector((0, 0, 1.44)), scale=(1.04, 0.98, 1.02), subdiv=True)
        
        # Dual-tier fantasy cheek flares
        for side, sgn in [("L", 1), ("R", -1)]:
            bm_f1 = create_cone(r1=0.18, r2=0.02, depth=0.55, u=16)
            add_mesh(f"CheekFlareUpper_{side}_{variant_type}", bm_f1, var_coll, m_purple,
                     location=root + Vector((sgn * 0.54, -0.06, 1.42)), scale=(1.0, 0.50, 0.80),
                     rotation=(math.radians(-10), math.radians(sgn * -68), math.radians(sgn * 14)))
            bm_f2 = create_cone(r1=0.14, r2=0.02, depth=0.44, u=14)
            add_mesh(f"CheekFlareLower_{side}_{variant_type}", bm_f2, var_coll, m_lime,
                     location=root + Vector((sgn * 0.50, -0.08, 1.28)), scale=(0.90, 0.48, 0.70),
                     rotation=(math.radians(14), math.radians(sgn * -78), math.radians(sgn * 32)))
            
        # Refined stylized fantasy muzzle
        bm_snout = create_sphere(radius=0.25, u=28, v=22)
        for v in bm_snout.verts:
            if v.co.y < 0:
                v.co.y *= 1.30
        add_mesh(f"Muzzle_{variant_type}", bm_snout, var_coll, m_cream,
                 location=root + Vector((0, -0.34, 1.34)), scale=(1.05, 1.05, 0.82), subdiv=True)
        
        # Heart-styled dark nose
        bm_nose = create_sphere(radius=0.058, u=18, v=14)
        add_mesh(f"Nose_{variant_type}", bm_nose, var_coll, m_nose,
                 location=root + Vector((0, -0.60, 1.38)), scale=(1.10, 0.70, 0.90))
        
        # Smile
        bm_mouth = create_cylinder(radius=0.014, depth=0.15, u=10)
        add_mesh(f"Mouth_{variant_type}", bm_mouth, var_coll, m_mouth,
                 location=root + Vector((0, -0.52, 1.27)), rotation=(0, math.radians(90), 0))
        
        # Fantasy Lynx/Fennec Ears with outer notch & feathered tips
        for side, sgn in [("L", 1), ("R", -1)]:
            bm_ear = create_cone(r1=0.27, r2=0.07, depth=0.55, u=20)
            for v in bm_ear.verts:
                v.co.x *= 0.66
            add_mesh(f"EarBase_{side}_{variant_type}", bm_ear, var_coll, m_purple,
                     location=root + Vector((sgn * 0.41, 0.04, 2.00)),
                     rotation=(math.radians(-10), math.radians(sgn * -20), math.radians(sgn * 12)))
            
            # Inner tuft feather
            bm_inner = create_cone(r1=0.17, r2=0.04, depth=0.45, u=16)
            add_mesh(f"EarInner_{side}_{variant_type}", bm_inner, var_coll, m_cream,
                     location=root + Vector((sgn * 0.38, -0.04, 1.98)),
                     rotation=(math.radians(-10), math.radians(sgn * -20), math.radians(sgn * 12)))
            
            # Whimsical curved lime feather tuft at ear tip
            bm_feather = create_cone(r1=0.08, r2=0.015, depth=0.36, u=14)
            add_mesh(f"EarFeather_{side}_{variant_type}", bm_feather, var_coll, m_lime,
                     location=root + Vector((sgn * 0.49, 0.08, 2.36)),
                     rotation=(math.radians(-22), math.radians(sgn * -36), math.radians(sgn * 22)))
            
        # Fantasy Layered Leaf/Flame Crest
        crest_configs = [
            (0, -0.10, 2.04, 0.14, 0.50, -18, 0),
            (0.11, -0.06, 2.00, 0.10, 0.40, -8, 16),
            (-0.11, -0.06, 2.00, 0.10, 0.40, -8, -16),
            (0, 0.02, 2.12, 0.12, 0.46, 8, 0)
        ]
        for idx, (cx, cy, cz, cr, cd, cp, cyaw) in enumerate(crest_configs):
            bm_crest = create_cone(r1=cr, r2=0.02, depth=cd, u=14)
            add_mesh(f"HairCrest_{idx}_{variant_type}", bm_crest, var_coll, m_lime,
                     location=root + Vector((cx, cy, cz)),
                     rotation=(math.radians(cp), math.radians(cyaw), 0))

    # Soft Pink Cheek Blush (Shared across all 3 variants)
    for sgn in [1, -1]:
        bm_b = create_sphere(radius=0.075, u=16, v=12)
        add_mesh(f"CheekBlush_{sgn}_{variant_type}", bm_b, var_coll, m_blush,
                 location=root + Vector((sgn * 0.38, -0.36, 1.28)), scale=(1.0, 0.30, 0.70))

    # =========================================================================
    # 2. EYES (VIBRANT EMERALD CARTOON EYES WITH TOP LINER & DUAL GLINTS)
    # =========================================================================
    eye_y = -0.38
    if variant_type == 'A':
        eye_scale = Vector((0.17, 0.08, 0.20)) # Expressive almond
        eye_x = 0.26
        eye_z = 1.48
    elif variant_type == 'B':
        eye_scale = Vector((0.21, 0.09, 0.23)) # Extra large round
        eye_x = 0.28
        eye_z = 1.44
    else: # C
        eye_scale = Vector((0.18, 0.08, 0.21)) # Elegant stylized
        eye_x = 0.26
        eye_z = 1.47
        
    for side, sgn in [("L", 1), ("R", -1)]:
        # Sclera white base
        bm_ew = create_sphere(radius=1.0, u=28, v=20)
        add_mesh(f"EyeWhite_{side}_{variant_type}", bm_ew, var_coll, m_eye_white,
                 location=root + Vector((sgn * eye_x, eye_y, eye_z)),
                 scale=eye_scale, rotation=(math.radians(6), math.radians(sgn * -4), 0))
        
        # Dark Upper Eyeliner Rim (Gives crisp readable anime/cartoon eye contour)
        bm_liner = create_cylinder(radius=0.032, depth=eye_scale.x * 2.2, u=14)
        add_mesh(f"EyeLiner_{side}_{variant_type}", bm_liner, var_coll, m_liner,
                 location=root + Vector((sgn * eye_x, eye_y - 0.04, eye_z + eye_scale.z * 0.82)),
                 rotation=(0, math.radians(sgn * 80), 0))
        
        # Emerald Iris Disc
        bm_iris = create_sphere(radius=1.0, u=24, v=18)
        add_mesh(f"Iris_{side}_{variant_type}", bm_iris, var_coll, m_iris,
                 location=root + Vector((sgn * (eye_x - 0.02), eye_y - 0.045, eye_z)), # slightly convergent gaze
                 scale=eye_scale * Vector((0.82, 0.85, 0.82)), rotation=(math.radians(6), math.radians(sgn * -4), 0))
        
        # Deep Black Pupil
        bm_pupil = create_sphere(radius=1.0, u=20, v=14)
        add_mesh(f"Pupil_{side}_{variant_type}", bm_pupil, var_coll, m_pupil,
                 location=root + Vector((sgn * (eye_x - 0.02), eye_y - 0.065, eye_z)),
                 scale=eye_scale * Vector((0.52, 0.70, 0.52)), rotation=(math.radians(6), math.radians(sgn * -4), 0))
        
        # Primary Specular Glint (Top-Left)
        bm_g1 = create_sphere(radius=0.042, u=14, v=10)
        add_mesh(f"Glint1_{side}_{variant_type}", bm_g1, var_coll, m_glint,
                 location=root + Vector((sgn * eye_x - 0.038, eye_y - 0.09, eye_z + 0.052)))
        # Secondary Specular Glint (Bottom-Right)
        bm_g2 = create_sphere(radius=0.022, u=12, v=8)
        add_mesh(f"Glint2_{side}_{variant_type}", bm_g2, var_coll, m_glint,
                 location=root + Vector((sgn * eye_x + 0.032, eye_y - 0.08, eye_z - 0.042)))
        
        # Eyebrows (Cute purple arches)
        bm_brow = create_cylinder(radius=0.028, depth=0.20, u=14)
        brow_pitch = 4 if variant_type == 'B' else (2 if variant_type == 'C' else 8)
        add_mesh(f"Eyebrow_{side}_{variant_type}", bm_brow, var_coll, m_purple,
                 location=root + Vector((sgn * eye_x, eye_y - 0.03, eye_z + 0.22)),
                 rotation=(math.radians(10), math.radians(sgn * brow_pitch), math.radians(sgn * -12)))

    # =========================================================================
    # 3. BODY & CLOTHING (TEAL HOODIE + SHORTS)
    # =========================================================================
    if variant_type == 'A':
        bm_torso = create_cylinder(radius=0.31, depth=0.74, u=24)
        add_mesh(f"Hoodie_{variant_type}", bm_torso, var_coll, m_teal,
                 location=root + Vector((0, 0, 0.84)), scale=(1.04, 0.86, 1.0), subdiv=True)
        bm_shorts = create_cylinder(radius=0.32, depth=0.28, u=24)
        add_mesh(f"Shorts_{variant_type}", bm_shorts, var_coll, m_shorts,
                 location=root + Vector((0, 0, 0.45)), scale=(1.02, 0.88, 1.0))
    elif variant_type == 'B':
        bm_torso = create_sphere(radius=0.43, u=28, v=20)
        add_mesh(f"Hoodie_{variant_type}", bm_torso, var_coll, m_teal,
                 location=root + Vector((0, 0, 0.79)), scale=(1.14, 0.95, 0.95), subdiv=True)
        bm_shorts = create_cylinder(radius=0.36, depth=0.22, u=24)
        add_mesh(f"Shorts_{variant_type}", bm_shorts, var_coll, m_shorts,
                 location=root + Vector((0, 0, 0.42)), scale=(1.10, 0.95, 1.0))
    else:
        bm_torso = create_cylinder(radius=0.33, depth=0.71, u=24)
        add_mesh(f"Hoodie_{variant_type}", bm_torso, var_coll, m_teal,
                 location=root + Vector((0, 0, 0.82)), scale=(1.02, 0.86, 1.0), subdiv=True)
        bm_shorts = create_cylinder(radius=0.33, depth=0.26, u=24)
        add_mesh(f"Shorts_{variant_type}", bm_shorts, var_coll, m_shorts,
                 location=root + Vector((0, 0, 0.44)), scale=(1.02, 0.88, 1.0))

    # Folded Hood Collar Ring around Neck
    bm_collar = create_cylinder(radius=0.34, depth=0.10, u=24)
    add_mesh(f"HoodCollar_{variant_type}", bm_collar, var_coll, m_hood_trim,
             location=root + Vector((0, -0.02, 1.15)), scale=(1.08, 0.85, 1.0))
    
    # Folded Hood Bulk at Back
    bm_hood = create_sphere(radius=0.30, u=24, v=16)
    add_mesh(f"HoodFold_{variant_type}", bm_hood, var_coll, m_teal,
             location=root + Vector((0, 0.18, 1.08)), scale=(1.10, 0.65, 0.70))
    
    # Kangaroo Pocket on Front of Hoodie
    bm_pocket = create_cylinder(radius=0.26, depth=0.18, u=20)
    add_mesh(f"HoodiePocket_{variant_type}", bm_pocket, var_coll, m_hood_trim,
             location=root + Vector((0, -0.22, 0.68)), scale=(0.95, 0.45, 1.0),
             rotation=(math.radians(12), 0, 0))
    
    # White Paw Print Logo on Chest
    bm_paw_c = create_cylinder(radius=0.058, depth=0.02, u=18)
    add_mesh(f"PawCenter_{variant_type}", bm_paw_c, var_coll, m_cream,
             location=root + Vector((0, -0.30, 0.92)), rotation=(math.radians(85), 0, 0))
    for p_x, p_z in [(-0.045, 0.99), (0.0, 1.01), (0.045, 0.99)]:
        bm_toe = create_cylinder(radius=0.018, depth=0.02, u=14)
        add_mesh(f"PawToe_{p_x}_{variant_type}", bm_toe, var_coll, m_cream,
                 location=root + Vector((p_x, -0.30, p_z)), rotation=(math.radians(85), 0, 0))

    # =========================================================================
    # 4. LIMBS (ARMS, LEGS, SOFT PAWS)
    # =========================================================================
    leg_len = 0.40 if variant_type == 'A' else (0.30 if variant_type == 'B' else 0.36)
    for side, sgn in [("L", 1), ("R", -1)]:
        # Sleeve
        bm_sleeve = create_cylinder(radius=0.12, depth=0.28, u=18)
        add_mesh(f"Sleeve_{side}_{variant_type}", bm_sleeve, var_coll, m_teal,
                 location=root + Vector((sgn * 0.42, 0, 0.86)),
                 rotation=(0, 0, math.radians(sgn * -24)))
        # Arm
        bm_arm = create_cylinder(radius=0.095, depth=0.30, u=18)
        add_mesh(f"Arm_{side}_{variant_type}", bm_arm, var_coll, m_purple,
                 location=root + Vector((sgn * 0.52, -0.04, 0.64)),
                 rotation=(math.radians(15), 0, math.radians(sgn * -16)))
        # Soft Paw Hand
        bm_hand = create_sphere(radius=0.13, u=20, v=16)
        add_mesh(f"Hand_{side}_{variant_type}", bm_hand, var_coll, m_cream,
                 location=root + Vector((sgn * 0.56, -0.08, 0.46)), scale=(1.0, 1.15, 0.90))
        
        # Leg
        bm_leg = create_cylinder(radius=0.11, depth=leg_len, u=18)
        add_mesh(f"Leg_{side}_{variant_type}", bm_leg, var_coll, m_purple,
                 location=root + Vector((sgn * 0.19, 0, 0.24)))
        # Foot Paw
        bm_foot = create_sphere(radius=0.15, u=22, v=16)
        add_mesh(f"Foot_{side}_{variant_type}", bm_foot, var_coll, m_cream,
                 location=root + Vector((sgn * 0.19, -0.08, 0.08)), scale=(0.95, 1.45, 0.65))

    # =========================================================================
    # 5. TAIL (SMOOTH CONTINUOUS ORGANIC LOFTED TUBE ARCHED TO THE SIDE)
    # =========================================================================
    # Arched dynamically towards Finny's left (viewer's right, positive X)
    if variant_type == 'A': # FOX-LEANING: Massive, dramatic, upward-sweeping bushy fox tail
        purple_pts = [
            Vector((0.08, 0.26, 0.46)),
            Vector((0.26, 0.44, 0.66)),
            Vector((0.52, 0.52, 0.96)),
            Vector((0.68, 0.40, 1.34)),
            Vector((0.64, 0.25, 1.58))
        ]
        purple_radii = [0.16, 0.28, 0.38, 0.36, 0.30]
        bm_t_base = create_smooth_tube(purple_pts, purple_radii, u=20)
        add_mesh(f"FoxTail_Base_{variant_type}", bm_t_base, var_coll, m_purple,
                 location=root, subdiv=True)
        
        # Seamless dramatic lime tip
        lime_pts = [
            Vector((0.64, 0.25, 1.58)),
            Vector((0.56, 0.15, 1.76)),
            Vector((0.38, 0.04, 1.94))
        ]
        lime_radii = [0.30, 0.22, 0.06]
        bm_t_tip = create_smooth_tube(lime_pts, lime_radii, u=20)
        add_mesh(f"FoxTail_Tip_{variant_type}", bm_t_tip, var_coll, m_lime,
                 location=root, subdiv=True)

    elif variant_type == 'B': # CAT/FOX HYBRID: Plump, pillow-soft rounded cloud tail
        purple_pts = [
            Vector((0.06, 0.24, 0.42)),
            Vector((0.22, 0.38, 0.56)),
            Vector((0.44, 0.46, 0.78)),
            Vector((0.58, 0.38, 1.06)),
            Vector((0.56, 0.24, 1.28))
        ]
        purple_radii = [0.18, 0.29, 0.38, 0.36, 0.32]
        bm_t_base = create_smooth_tube(purple_pts, purple_radii, u=20)
        add_mesh(f"PlushTail_Base_{variant_type}", bm_t_base, var_coll, m_purple,
                 location=root, subdiv=True)
        
        # Soft rounded lime marshmallow tip
        lime_pts = [
            Vector((0.56, 0.24, 1.28)),
            Vector((0.48, 0.12, 1.44)),
            Vector((0.36, 0.04, 1.54))
        ]
        lime_radii = [0.32, 0.24, 0.10]
        bm_t_tip = create_smooth_tube(lime_pts, lime_radii, u=20)
        add_mesh(f"PlushTail_Tip_{variant_type}", bm_t_tip, var_coll, m_lime,
                 location=root, subdiv=True)

    else: # FANTASY COMPANION: Whimsical flame/feather curved tail with stepped lime fins
        purple_pts = [
            Vector((0.08, 0.25, 0.44)),
            Vector((0.24, 0.42, 0.64)),
            Vector((0.48, 0.48, 0.92)),
            Vector((0.62, 0.36, 1.26)),
            Vector((0.58, 0.22, 1.52))
        ]
        purple_radii = [0.16, 0.26, 0.35, 0.32, 0.26]
        bm_t_base = create_smooth_tube(purple_pts, purple_radii, u=20)
        add_mesh(f"FantasyTail_Base_{variant_type}", bm_t_base, var_coll, m_purple,
                 location=root, subdiv=True)
        
        # Swept lime flame tip
        lime_pts = [
            Vector((0.58, 0.22, 1.52)),
            Vector((0.48, 0.12, 1.68)),
            Vector((0.32, 0.02, 1.82))
        ]
        lime_radii = [0.26, 0.18, 0.06]
        bm_t_tip = create_smooth_tube(lime_pts, lime_radii, u=20)
        add_mesh(f"FantasyTail_Tip_{variant_type}", bm_t_tip, var_coll, m_lime,
                 location=root, subdiv=True)
        
        # Stepped whimsical lime feather tufts along outer curve
        for f_i, (floc, frot, fscl) in enumerate([
            (Vector((0.58, 0.48, 0.96)), (math.radians(-55), math.radians(45), math.radians(50)), 0.24),
            (Vector((0.70, 0.34, 1.24)), (math.radians(-75), math.radians(35), math.radians(40)), 0.22),
            (Vector((0.56, 0.14, 1.58)), (math.radians(-105), math.radians(25), math.radians(30)), 0.19)
        ]):
            bm_tf = create_cone(r1=fscl*0.55, r2=0.015, depth=fscl*2.2, u=14)
            add_mesh(f"TailFeather_{f_i}_{variant_type}", bm_tf, var_coll, m_lime,
                     location=root + floc, rotation=frot)

    return var_coll

def setup_studio():
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE'
    
    # World setup: Clean soft studio environment
    world = bpy.data.worlds.new("StudioWorld")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes.clear()
    
    bg = world.node_tree.nodes.new(type='ShaderNodeBackground')
    bg.name = "StudioBackground"
    bg.inputs['Color'].default_value = (0.91, 0.91, 0.93, 1.0)
    bg.inputs['Strength'].default_value = 0.85
    
    out_w = world.node_tree.nodes.new(type='ShaderNodeOutputWorld')
    world.node_tree.links.new(bg.outputs['Background'], out_w.inputs['Surface'])
    
    # Shadow-Catcher Ground Floor
    bm_floor = bmesh.new()
    bmesh.ops.create_grid(bm_floor, x_segments=2, y_segments=2, size=40.0)
    m_floor = create_pbr_material("Mat_StudioFloor", (0.86, 0.86, 0.89, 1.0), roughness=0.65)
    add_mesh("StudioFloor", bm_floor, scene.collection, m_floor, location=(0,0,-0.02))
    
    # Studio Lighting Rig
    light_coll = bpy.data.collections.new("Studio_Lights")
    scene.collection.children.link(light_coll)
    
    # Key Light (Warm soft studio area light)
    k_data = bpy.data.lights.new("KeyLight", type='AREA')
    k_data.energy = 850.0
    k_data.size = 5.5
    k_data.color = (1.0, 0.98, 0.94)
    k_obj = bpy.data.objects.new("KeyLight", k_data)
    k_obj.location = (-4.0, -6.0, 4.8)
    k_obj.rotation_euler = (math.radians(48), 0, math.radians(-32))
    light_coll.objects.link(k_obj)
    
    # Fill Light (Cool soft fill)
    f_data = bpy.data.lights.new("FillLight", type='AREA')
    f_data.energy = 380.0
    f_data.size = 6.5
    f_data.color = (0.88, 0.94, 1.0)
    f_obj = bpy.data.objects.new("FillLight", f_data)
    f_obj.location = (4.8, -5.2, 4.0)
    f_obj.rotation_euler = (math.radians(52), 0, math.radians(42))
    light_coll.objects.link(f_obj)
    
    # High-Angle Back Rim Light (Accentuates fur silhouette, ears, and tail)
    r_data = bpy.data.lights.new("RimLight", type='SPOT')
    r_data.energy = 1200.0
    r_data.spot_size = math.radians(95)
    r_data.color = (0.96, 1.0, 0.94)
    r_obj = bpy.data.objects.new("RimLight", r_data)
    r_obj.location = (0.0, 5.5, 5.2)
    r_obj.rotation_euler = (math.radians(-50), 0, math.radians(180))
    light_coll.objects.link(r_obj)

def create_camera(name, loc, rot, lens=50.0):
    cam_data = bpy.data.cameras.new(name)
    cam_data.lens = lens
    cam_obj = bpy.data.objects.new(name, cam_data)
    cam_obj.location = loc
    cam_obj.rotation_euler = rot
    bpy.context.scene.collection.objects.link(cam_obj)
    return cam_obj

def set_silhouette_mode(enable=True):
    scene = bpy.context.scene
    bg = scene.world.node_tree.nodes.get('StudioBackground')
    floor = bpy.data.objects.get("StudioFloor")
    mat_sil = bpy.data.materials.get("Mat_Silhouette_Black")
    
    if enable:
        if bg:
            bg.inputs['Color'].default_value = (1.0, 1.0, 1.0, 1.0)
            bg.inputs['Strength'].default_value = 1.0
        if floor:
            floor.hide_render = True
        for obj in bpy.data.objects:
            if obj.type == 'MESH' and obj.name != "StudioFloor":
                if "_orig_mats" not in obj:
                    obj["_orig_mats"] = [slot.material.name if slot.material else "" for slot in obj.material_slots]
                for slot in obj.material_slots:
                    slot.material = mat_sil
    else:
        if bg:
            bg.inputs['Color'].default_value = (0.91, 0.91, 0.93, 1.0)
            bg.inputs['Strength'].default_value = 0.85
        if floor:
            floor.hide_render = False
        for obj in bpy.data.objects:
            if obj.type == 'MESH' and "_orig_mats" in obj:
                for idx, mat_name in enumerate(obj["_orig_mats"]):
                    if idx < len(obj.material_slots):
                        obj.material_slots[idx].material = bpy.data.materials.get(mat_name)

def render_view(cam, filepath, res_x=1080, res_y=1080):
    scene = bpy.context.scene
    scene.camera = cam
    scene.render.resolution_x = res_x
    scene.render.resolution_y = res_y
    scene.render.filepath = filepath
    print(f"Rendering: {os.path.basename(filepath)} ({res_x}x{res_y})...")
    bpy.ops.render.render(write_still=True)

def isolate_variant(var_to_show):
    for v in ['A', 'B', 'C']:
        coll = bpy.data.collections.get(f"Finny_Variant_{v}")
        if coll:
            coll.hide_render = False if (var_to_show == 'ALL' or var_to_show == v) else True

def main():
    print("=== Finny Character Exploration Generator & Renderer ===")
    clear_all()
    
    # 1. Colors & Materials Palette (Matching Concept Art)
    materials = {
        "purple": create_pbr_material("Mat_Fur_Purple", (0.47, 0.24, 0.66, 1.0), roughness=0.55),
        "lime": create_pbr_material("Mat_Fur_Lime", (0.58, 0.92, 0.16, 1.0), roughness=0.45),
        "cream": create_pbr_material("Mat_Cream", (0.98, 0.92, 0.84, 1.0), roughness=0.52),
        "teal": create_pbr_material("Mat_Teal_Hoodie", (0.15, 0.65, 0.68, 1.0), roughness=0.46),
        "hood_trim": create_pbr_material("Mat_Teal_Trim", (0.12, 0.54, 0.57, 1.0), roughness=0.48),
        "shorts": create_pbr_material("Mat_Shorts", (0.52, 0.39, 0.30, 1.0), roughness=0.62),
        "nose": create_pbr_material("Mat_Nose_Dark", (0.15, 0.08, 0.20, 1.0), roughness=0.25),
        "mouth": create_pbr_material("Mat_Mouth", (0.22, 0.10, 0.26, 1.0), roughness=0.40),
        "blush": create_pbr_material("Mat_Blush", (1.0, 0.65, 0.65, 1.0), roughness=0.60),
        "eye_white": create_pbr_material("Mat_Eye_White", (0.99, 0.99, 1.0, 1.0), roughness=0.06, specular=0.9),
        "iris": create_pbr_material("Mat_Eye_Iris", (0.06, 0.88, 0.36, 1.0), roughness=0.04, specular=0.95),
        "pupil": create_pbr_material("Mat_Eye_Pupil", (0.02, 0.02, 0.03, 1.0), roughness=0.04, specular=0.98),
        "liner": create_pbr_material("Mat_Eye_Liner", (0.12, 0.06, 0.18, 1.0), roughness=0.30),
        "glint": create_pbr_material("Mat_Eye_Glint", (1.0, 1.0, 1.0, 1.0), roughness=0.0,
                                     emission_srgb=(1.0, 1.0, 1.0, 1.0), emission_strength=2.8)
    }
    create_silhouette_material()
    
    setup_studio()
    
    # 2. Build the 3 Variants:
    # A at X = -2.6, B at X = 0.0, C at X = +2.6
    build_finny_character('A', offset_x=-2.6, materials=materials)
    build_finny_character('B', offset_x=0.0, materials=materials)
    build_finny_character('C', offset_x=2.6, materials=materials)
    
    out_dir = "d:/Finny/assets/exploration/renders"
    os.makedirs(out_dir, exist_ok=True)
    blend_path = "d:/Finny/assets/exploration/finny_exploration.blend"
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f"Blender scene saved: {blend_path}")
    
    # 3. Setup Cameras with Flawless Framing
    cam_comp = create_camera("Cam_Comparison", loc=(0, -8.6, 1.30), rot=(math.radians(88), 0, 0), lens=40.0)
    
    var_offsets = {'A': -2.6, 'B': 0.0, 'C': 2.6}
    cams = {}
    for v, ox in var_offsets.items():
        # Front View (Frames full body Z=0 to Z=2.6 + tail with comfortable margin)
        cams[f"{v}_front"] = create_camera(
            f"Cam_{v}_Front", loc=(ox, -4.8, 1.25), rot=(math.radians(88), 0, 0), lens=48.0)
        
        # 3/4 Perspective View
        cams[f"{v}_34"] = create_camera(
            f"Cam_{v}_34", loc=(ox + 3.2, -4.0, 1.45), rot=(math.radians(82), 0, math.radians(38)), lens=48.0)
        
        # Side Profile View (Pure 90° view)
        cams[f"{v}_side"] = create_camera(
            f"Cam_{v}_Side", loc=(ox + 5.0, 0, 1.25), rot=(math.radians(90), 0, math.radians(90)), lens=48.0)
        
        # Face Close-Up (Frames head, eyes, muzzle, ears, and hair tuft)
        cams[f"{v}_face"] = create_camera(
            f"Cam_{v}_Face", loc=(ox, -2.6, 1.50), rot=(math.radians(88), 0, 0), lens=65.0)
        
        # Silhouette View (3/4 angle gives maximum silhouette distinctiveness)
        cams[f"{v}_sil"] = create_camera(
            f"Cam_{v}_Sil", loc=(ox + 3.2, -4.0, 1.45), rot=(math.radians(82), 0, math.radians(38)), lens=48.0)

    # 4. Render All Views
    # A) Comparison Color Shot
    isolate_variant('ALL')
    set_silhouette_mode(False)
    render_view(cam_comp, f"{out_dir}/finny_comparison_color.png", res_x=2560, res_y=1200)
    
    # B) Comparison Black Silhouette Shot
    set_silhouette_mode(True)
    render_view(cam_comp, f"{out_dir}/finny_comparison_silhouette.png", res_x=2560, res_y=1200)
    
    # C) Individual Renders per Variant
    for v in ['A', 'B', 'C']:
        isolate_variant(v)
        
        # Color renders
        set_silhouette_mode(False)
        render_view(cams[f"{v}_front"], f"{out_dir}/variant_{v.lower()}_front.png", 1080, 1080)
        render_view(cams[f"{v}_34"], f"{out_dir}/variant_{v.lower()}_three_quarter.png", 1080, 1080)
        render_view(cams[f"{v}_side"], f"{out_dir}/variant_{v.lower()}_side.png", 1080, 1080)
        render_view(cams[f"{v}_face"], f"{out_dir}/variant_{v.lower()}_face.png", 1080, 1080)
        
        # Black silhouette render
        set_silhouette_mode(True)
        render_view(cams[f"{v}_sil"], f"{out_dir}/variant_{v.lower()}_silhouette.png", 1080, 1080)

    # Reset scene
    set_silhouette_mode(False)
    isolate_variant('ALL')
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print("=== All Exploration Renders Successfully Generated! ===")

if __name__ == "__main__":
    main()
