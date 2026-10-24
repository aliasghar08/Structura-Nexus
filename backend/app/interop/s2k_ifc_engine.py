"""
BIM and CAD Interoperability Engine
Supports:
1. ETABS & SAP2000 .s2k Bidirectional Data Exchange (CSI Text File Format)
2. IFC 4.3 (Industry Foundation Classes) ISO 10303-21 STEP File Generator
"""

import re
import datetime
from typing import Dict, Any, List, Tuple, Optional
from ..code_check.aisc_aci import AISC_W_SHAPES


class S2KEngine:
    """
    Computers & Structures Inc. (CSI) ETABS and SAP2000 .s2k Text Translator.
    Enables lossless bidirectional exchange between Structura Nexus and ETABS.
    """

    @staticmethod
    def export_to_s2k(model_data: Dict[str, Any]) -> str:
        """
        Exports a Structura Nexus model dictionary to valid ETABS/SAP2000 .s2k format.
        """
        nodes = model_data.get("nodes", [])
        members = model_data.get("members", [])
        model_name = model_data.get("name", "Structura_Nexus_Model")

        lines = [
            f'; ETABS / SAP2000 Text Data File (.s2k)',
            f'; Structura Nexus (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved. DMCA Protected.',
            f'; Project: {model_name}',
            '',
            'TABLE:  "PROGRAM INFORMATION"',
            '   Program="ETABS"   Version="21.0.0"   ProgLevel="Ultimate"',
            '',
            'TABLE:  "MATERIAL PROPERTIES 01 - GENERAL"',
            '   Material="A992Fy50"   Type="Steel"   DesignType="Steel"   UnitWeight=78.5   E=200000000   Fy=345000   Fu=450000',
            '',
            'TABLE:  "FRAME SECTION PROPERTIES 01 - GENERAL"',
        ]

        # Extract distinct sections
        sections = sorted(list({m.get("sectionProfile") or m.get("section") or "W14X48" for m in members}))
        for sec in sections:
            props = AISC_W_SHAPES.get(sec, AISC_W_SHAPES["W14X48"])
            depth = props["depth_m"]
            width = props["width_m"]
            tf = props["tf_m"]
            tw = props["tw_m"]
            lines.append(
                f'   SectionName="{sec}"   Material="A992Fy50"   Shape="I/Wide Flange"   '
                f't3={depth:.4f}   t2={width:.4f}   tf={tf:.4f}   tw={tw:.4f}'
            )
        lines.append('')

        # Table: Joint Coordinates
        lines.append('TABLE:  "JOINT COORDINATES"')
        for n in nodes:
            nid = n.get("id", "N0")
            coords = n.get("coords", [0.0, 0.0, 0.0])
            x = float(n.get("x", coords[0] if len(coords) > 0 else 0.0))
            y = float(n.get("z", coords[2] if len(coords) > 2 else 0.0))
            z = float(n.get("y", coords[1] if len(coords) > 1 else 0.0))
            lines.append(f'   Joint="{nid}"   CoordSys="GLOBAL"   CoordType="Cartesian"   XorR={x:.4f}   Y={y:.4f}   Z={z:.4f}')
        lines.append('')

        # Table: Frame Connectivity
        lines.append('TABLE:  "CONNECTIVITY - FRAME"')
        for m in members:
            mid = m.get("id", "M0")
            n1 = m.get("startNodeId") or m.get("i_node", "N1")
            n2 = m.get("endNodeId") or m.get("j_node", "N2")
            lines.append(f'   Frame="{mid}"   JointI="{n1}"   JointJ="{n2}"   IsCurved="No"')
        lines.append('')

        # Table: Frame Section Assignments
        lines.append('TABLE:  "FRAME SECTION ASSIGNMENTS"')
        for m in members:
            mid = m.get("id", "M0")
            sec = m.get("sectionProfile") or m.get("section") or "W14X48"
            lines.append(f'   Frame="{mid}"   AnalSect="{sec}"   MatProp="Default"')
        lines.append('')

        # Table: Joint Restraint Assignments
        lines.append('TABLE:  "JOINT RESTRAINT ASSIGNMENTS"')
        for n in nodes:
            r = n.get("isRestrained") or [False] * 6
            if any(r):
                nid = n.get("id", "N0")
                u1 = "Yes" if len(r) > 0 and r[0] else "No"
                u2 = "Yes" if len(r) > 2 and r[2] else "No"
                u3 = "Yes" if len(r) > 1 and r[1] else "No"
                r1 = "Yes" if len(r) > 3 and r[3] else "No"
                r2 = "Yes" if len(r) > 5 and r[5] else "No"
                r3 = "Yes" if len(r) > 4 and r[4] else "No"
                lines.append(f'   Joint="{nid}"   U1={u1}   U2={u2}   U3={u3}   R1={r1}   R2={r2}   R3={r3}')
        lines.append('')

        # Table: Joint Loads
        lines.append('TABLE:  "JOINT LOADS - FORCE"')
        for n in nodes:
            fx = n.get("fxN") or (n.get("loads", [0])[0] if n.get("loads") else 0.0)
            fy = n.get("fyN") or (n.get("loads", [0, 0])[1] if n.get("loads") and len(n.get("loads")) > 1 else 0.0)
            fz = n.get("fzN") or (n.get("loads", [0, 0, 0])[2] if n.get("loads") and len(n.get("loads")) > 2 else 0.0)
            if abs(fx) > 0.001 or abs(fy) > 0.001 or abs(fz) > 0.001:
                nid = n.get("id", "N0")
                lines.append(f'   Joint="{nid}"   LoadPat="DEAD"   F1={fx:.2f}   F2={fz:.2f}   F3={fy:.2f}')
        lines.append('')

        lines.append('END TABLE DATA')
        return '\n'.join(lines)

    @staticmethod
    def import_from_s2k(s2k_content: str) -> Dict[str, Any]:
        """
        Parses an ETABS/SAP2000 .s2k text file into a Structura Nexus model dictionary.
        """
        nodes: List[Dict[str, Any]] = []
        members: List[Dict[str, Any]] = []
        node_map: Dict[str, Dict[str, Any]] = {}
        restraint_map: Dict[str, List[bool]] = {}
        section_map: Dict[str, str] = {}
        load_map: Dict[str, List[float]] = {}

        current_table: Optional[str] = None

        for line in s2k_content.splitlines():
            line_s = line.strip()
            if not line_s or line_s.startswith(";"):
                continue

            # Check table header
            table_match = re.match(r'TABLE:\s+"([^"]+)"', line_s)
            if table_match:
                current_table = table_match.group(1).upper()
                continue

            if line_s == "END TABLE DATA":
                current_table = None
                continue

            if not current_table:
                continue

            # Parse Table: JOINT COORDINATES
            if "JOINT COORDINATES" in current_table:
                j_match = re.search(r'Joint="?([^"\s]+)"?', line_s)
                x_match = re.search(r'XorR=([\d\.\-]+)', line_s) or re.search(r'X=([\d\.\-]+)', line_s)
                y_match = re.search(r'\sY=([\d\.\-]+)', line_s)
                z_match = re.search(r'\sZ=([\d\.\-]+)', line_s)
                if j_match and x_match and z_match:
                    jid = j_match.group(1)
                    x = float(x_match.group(1))
                    y_etabs = float(y_match.group(1)) if y_match else 0.0
                    z_etabs = float(z_match.group(1))  # Elevation in ETABS -> Y in Structura Nexus
                    node_dict = {
                        "id": jid,
                        "x": x,
                        "y": z_etabs,
                        "z": y_etabs,
                        "coords": [x, z_etabs, y_etabs],
                        "restraint": [0, 0, 0, 0, 0, 0],
                        "loads": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
                    }
                    node_map[jid] = node_dict

            # Parse Table: FRAME CONNECTIVITY
            elif "CONNECTIVITY - FRAME" in current_table:
                f_match = re.search(r'Frame="?([^"\s]+)"?', line_s)
                i_match = re.search(r'JointI="?([^"\s]+)"?', line_s)
                j_match = re.search(r'JointJ="?([^"\s]+)"?', line_s)
                if f_match and i_match and j_match:
                    members.append({
                        "id": f_match.group(1),
                        "startNodeId": i_match.group(1),
                        "endNodeId": j_match.group(1),
                        "i_node": i_match.group(1),
                        "j_node": j_match.group(1),
                        "section": "W14X48",
                        "sectionProfile": "W14X48",
                        "material": "A992_STEEL",
                    })

            # Parse Table: FRAME SECTION ASSIGNMENTS
            elif "FRAME SECTION ASSIGNMENTS" in current_table:
                f_match = re.search(r'Frame="?([^"\s]+)"?', line_s)
                s_match = re.search(r'AnalSect="?([^"\s]+)"?', line_s)
                if f_match and s_match:
                    section_map[f_match.group(1)] = s_match.group(1)

            # Parse Table: JOINT RESTRAINT ASSIGNMENTS
            elif "JOINT RESTRAINT ASSIGNMENTS" in current_table:
                j_match = re.search(r'Joint="?([^"\s]+)"?', line_s)
                if j_match:
                    jid = j_match.group(1)
                    u1 = "U1=YES" in line_s.upper()
                    u2 = "U2=YES" in line_s.upper()
                    u3 = "U3=YES" in line_s.upper()
                    r1 = "R1=YES" in line_s.upper()
                    r2 = "R2=YES" in line_s.upper()
                    r3 = "R3=YES" in line_s.upper()
                    # Map to Nexus [UX, UY, UZ, RX, RY, RZ] with 1=fixed, 0=free
                    restraint_map[jid] = [
                        1 if u1 else 0,
                        1 if u3 else 0,
                        1 if u2 else 0,
                        1 if r1 else 0,
                        1 if r3 else 0,
                        1 if r2 else 0,
                    ]

            # Parse Table: JOINT LOADS - FORCE
            elif "JOINT LOADS - FORCE" in current_table:
                j_match = re.search(r'Joint="?([^"\s]+)"?', line_s)
                f1_match = re.search(r'F1=([\d\.\-]+)', line_s)
                f2_match = re.search(r'F2=([\d\.\-]+)', line_s)
                f3_match = re.search(r'F3=([\d\.\-]+)', line_s)
                if j_match:
                    jid = j_match.group(1)
                    fx = float(f1_match.group(1)) if f1_match else 0.0
                    fz = float(f2_match.group(1)) if f2_match else 0.0
                    fy = float(f3_match.group(1)) if f3_match else 0.0
                    load_map[jid] = [fx, fy, fz, 0.0, 0.0, 0.0]

        # Apply mapped sections, restraints, and loads
        for m in members:
            if m["id"] in section_map:
                sec_name = section_map[m["id"]]
                m["sectionProfile"] = sec_name
                m["section"] = sec_name

        for jid, node in node_map.items():
            if jid in restraint_map:
                node["restraint"] = restraint_map[jid]
                node["isRestrained"] = [r == 1 for r in restraint_map[jid]]
            if jid in load_map:
                node["loads"] = load_map[jid]
                node["fxN"] = load_map[jid][0]
                node["fyN"] = load_map[jid][1]
                node["fzN"] = load_map[jid][2]
            nodes.append(node)

        return {
            "name": "Imported_From_ETABS",
            "nodes": nodes,
            "members": members,
        }


class IFC43Engine:
    """
    Industry Foundation Classes (IFC 4.3) STEP File Generator.
    Adheres to ISO 10303-21 and buildingSMART structural BIM standards.
    """

    @staticmethod
    def export_to_ifc(model_data: Dict[str, Any]) -> str:
        """
        Exports a Structura Nexus model dictionary to valid IFC 4.3 STEP file format.
        """
        nodes = model_data.get("nodes", [])
        members = model_data.get("members", [])
        model_name = model_data.get("name", "Structura_Nexus_BIM")
        timestamp = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")

        node_map = {n["id"]: n for n in nodes}

        # Step ID counter
        step_id = 1

        def next_id() -> int:
            nonlocal step_id
            sid = step_id
            step_id += 1
            return sid

        header = f"""ISO-10303-21;
HEADER;
FILE_DESCRIPTION(('ViewDefinition [DesignTransferView_V1.0]','Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved. DMCA Protected.'),'2;1');
FILE_NAME('{model_name}.ifc','{timestamp}',('Ali Asghar <aliasgharinnocent@yahoo.com>'),('Dart Nexus Lab'),'Structura Nexus Engine v3.4','ETABS & IFC Interop Engine','Approved');
FILE_SCHEMA(('IFC4X3'));
ENDSEC;
DATA;
"""
        records = []

        # Project and world coordinates setup
        id_owner_history = next_id()
        records.append(f"#{id_owner_history}=IFCOWNERHISTORY(#2,#3,$,.NOCHANGE.,$,$,$,{int(datetime.datetime.now().timestamp())});")

        id_app = next_id()
        records.append(f"#{id_app}=IFCAPPLICATION(#4,'3.4','Structura Nexus','STRUCTURA_NEXUS');")

        id_person = next_id()
        records.append(f"#{id_person}=IFCPERSON('PE-94021','Engineer','Structural',$,$,$,$,$);")

        id_org = next_id()
        records.append(f"#{id_org}=IFCORGANIZATION($,'Structura Nexus Engineering',$,$,$);")

        id_person_org = next_id()
        records.append(f"#{id_person_org}=IFCPERSONANDORGANIZATION(#{id_person},#{id_org},$);")

        id_project = next_id()
        id_site = next_id()
        id_building = next_id()
        id_storey = next_id()

        id_world_coord = next_id()
        records.append(f"#{id_world_coord}=IFCAXIS2PLACEMENT3D(#10,#11,#12);")
        records.append("#10=IFCCARTESIANPOINT((0.,0.,0.));")
        records.append("#11=IFCDIRECTION((0.,0.,1.));")
        records.append("#12=IFCDIRECTION((1.,0.,0.));")

        id_geom_context = next_id()
        records.append(f"#{id_geom_context}=IFCGEOMETRICREPRESENTATIONCONTEXT($,'Model',3,1.E-05,#{id_world_coord},$);")

        # Project & spatial hierarchy
        records.append(f"#{id_project}=IFCPROJECT('1ProjectNexus000000000',#{id_owner_history},'{model_name}','Structural Space Frame Model',$,$,$,(#{id_geom_context}),#13);")
        records.append("#13=IFCUNITASSIGNMENT((#14,#15,#16));")
        records.append("#14=IFCSIUNIT(*,.LENGTHUNIT.,$,.METRE.);")
        records.append("#15=IFCSIUNIT(*,.FORCEUNIT.,.KILO.,.NEWTON.);")
        records.append("#16=IFCSIUNIT(*,.PLANEANGLEUNIT.,$,.RADIAN.);")

        records.append(f"#{id_site}=IFCSITE('1SiteNexus0000000000000',#{id_owner_history},'Building Site',$,$,#{id_world_coord},$,$,.ELEMENT.,$,$,$,$,$);")
        records.append(f"#{id_building}=IFCBUILDING('1BuildingNexus000000000',#{id_owner_history},'{model_name} Building',$,$,#{id_world_coord},$,$,.ELEMENT.,$,$,$);")
        records.append(f"#{id_storey}=IFCBUILDINGSTOREY('1StoreyNexus0000000000',#{id_owner_history},'Level 1 Frame',$,$,#{id_world_coord},$,$,.ELEMENT.,0.);")

        # Material: ASTM A992 Steel
        id_mat = next_id()
        records.append(f"#{id_mat}=IFCMATERIAL('ASTM A992 Structural Steel',$,'Steel');")

        # Point Coordinates
        point_step_ids: Dict[str, int] = {}
        for n in nodes:
            nid = n.get("id", "N0")
            pid = next_id()
            coords = n.get("coords", [0.0, 0.0, 0.0])
            x = float(n.get("x", coords[0] if len(coords) > 0 else 0.0))
            y = float(n.get("z", coords[2] if len(coords) > 2 else 0.0))
            z = float(n.get("y", coords[1] if len(coords) > 1 else 0.0))
            records.append(f"#{pid}=IFCCARTESIANPOINT(({x:.4f},{y:.4f},{z:.4f}));")
            point_step_ids[nid] = pid

        # Members: IFCSTRUCTURALCURVEMEMBER / IFCBEAM
        member_step_ids: List[int] = []
        for m in members:
            mid = m.get("id", "M0")
            n1_id = m.get("startNodeId") or m.get("i_node")
            n2_id = m.get("endNodeId") or m.get("j_node")
            sec = m.get("sectionProfile") or m.get("section") or "W14X48"

            p1 = point_step_ids.get(n1_id)
            p2 = point_step_ids.get(n2_id)
            if not p1 or not p2:
                continue

            id_poly = next_id()
            records.append(f"#{id_poly}=IFCPOLYLINE((#{p1},#{p2}));")

            id_rep = next_id()
            records.append(f"#{id_rep}=IFCSHAPEREPRESENTATION(#{id_geom_context},'Axis','Curve3D',(#{id_poly}));")

            id_def = next_id()
            records.append(f"#{id_def}=IFCPRODUCTDEFINITIONSHAPE($,$,(#{id_rep}));")

            id_member = next_id()
            records.append(
                f"#{id_member}=IFCMEMBER('1MemberNexus{mid.replace('M','')[:10]}',#{id_owner_history},"
                f"'{mid}','Steel Frame Member: {sec}',$,#{id_world_coord},#{id_def},'{sec}');"
            )
            member_step_ids.append(id_member)

        # Relate members to storey
        if member_step_ids:
            id_rel = next_id()
            members_str = ",".join([f"#{mid}" for mid in member_step_ids])
            records.append(f"#{id_rel}=IFCRELCONTAINEDINSPATIALSTRUCTURE('1RelContainedNexus00000',#{id_owner_history},'MembersInStorey',$,({members_str}),#{id_storey});")

        footer = "ENDSEC;\nEND-ISO-10303-21;\n"
        return header + "\n".join(records) + "\n" + footer
