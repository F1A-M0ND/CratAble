from pathlib import Path
from copy import deepcopy
import json,subprocess,hashlib,sys
from docx import Document
from docx.shared import Pt,Inches,Cm,RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

sys.stdout.reconfigure(encoding='utf-8')
ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parent/'CratAble_บทที่1-3_แผนประเมิน.docx'
before=hashlib.sha256(SOURCE.read_bytes()).hexdigest()
doc=Document(SOURCE)
# Reuse the verified school layout and styles; retain the source unchanged.
body=doc.element.body
sect=deepcopy(body.sectPr)
for node in list(body): body.remove(node)
body.append(sect)
num=sect.find(qn('w:pgNumType'))
if num is not None: num.set(qn('w:start'),'1')
doc.core_properties.title='บทที่ 2 เอกสารและงานวิจัยที่เกี่ยวข้อง'
doc.core_properties.subject='ฉบับปรับปรุงเน้นข้อมูลและแนวคิดการประเมินต้นแบบขนาดเล็ก'
pending=False
def para(s,style=None,center=False,indent=True):
    global pending
    x=doc.add_paragraph(s,style)
    pf=x.paragraph_format
    pf.space_before=Pt(0);pf.space_after=Pt(3);pf.line_spacing=1
    if pending: pf.page_break_before=True; pending=False
    x.alignment=WD_ALIGN_PARAGRAPH.CENTER if center else (WD_ALIGN_PARAGRAPH.THAI_JUSTIFY if indent else WD_ALIGN_PARAGRAPH.LEFT)
    if indent and not center and not style:pf.first_line_indent=Inches(.5)
    return x
def p(s):return para(s)
def h(s):
    x=para(s,'Heading 2',indent=False);x.paragraph_format.space_before=Pt(4);return x
def page():
    global pending
    pending=True

para('บทที่ 2\nเอกสารและงานวิจัยที่เกี่ยวข้อง','Title',center=True)
h('2.1 เกมการ์ดและโต๊ะเสมือน')
p('เกมการ์ดใช้การ์ดเป็นสื่อแสดงข้อมูลและใช้พื้นที่จัดวางเพื่อสื่อสถานะของการเล่น การ์ดใบเดียวกันอาจอยู่ในกอง อยู่ในมือ หรือวางบนโต๊ะ ซึ่งแต่ละตำแหน่งมีความหมายตามกติกาของเกม การพัฒนาเครื่องมือสำหรับเกมหลายรูปแบบจึงต้องแยกส่วนประกอบที่ใช้ร่วมกันออกจากกติกาเฉพาะเกม เช่น แยกการย้ายการ์ดออกจากเงื่อนไขว่าผู้เล่นได้รับอนุญาตให้ย้ายเมื่อใด')
p('โต๊ะเสมือนในโครงงานนี้หมายถึงพื้นที่ดิจิทัลที่ให้ผู้ใช้จัดวางและควบคุมอุปกรณ์แทนโต๊ะจริง ผู้เล่นตกลงกติกาและตัดสินผลเอง ส่วนแพลตฟอร์มจัดเตรียมการ์ด เด็ค ที่วางการ์ด ลูกเต๋า และตัวนับคะแนน แนวคิดนี้สัมพันธ์กับการศึกษาองค์ประกอบร่วมและปฏิสัมพันธ์ของเกมการ์ดของ Steinböck (2017) ซึ่งช่วยอธิบายว่าการใช้เครื่องมือชุดเดียวรองรับเกมต่างรูปแบบได้โดยไม่ต้องกำหนดกติกาตายตัวทั้งหมด')
h('2.2 การสร้างต้นแบบและข้อมูลส่วนประกอบของเกม')
p('ต้นแบบเกมเป็นรูปแบบที่ใช้ทดลองแนวคิดก่อนพัฒนารายละเอียดให้สมบูรณ์ สำหรับโครงงานนี้ ต้นแบบประกอบด้วยภาพและขนาดการ์ด จำนวนการ์ดแต่ละชนิดในเด็ค ขนาดโต๊ะ และตำแหน่งอุปกรณ์ ผู้สร้างสามารถแก้ส่วนประกอบแล้วนำกลับไปทดลองเล่น เพื่อพิจารณาว่าอุปกรณ์และพื้นที่เพียงพอต่อแนวคิดของเกมหรือไม่')
p('ข้อมูลต้นแบบควรแยกภาพการ์ดออกจากข้อมูลการใช้งาน เช่น รหัสการ์ด ชื่อ ขนาด และจำนวนสำเนา เด็คต้องเก็บชนิดและจำนวนการ์ด ส่วนสนามเก็บขนาดโต๊ะ ชนิดอุปกรณ์ และตำแหน่ง ความแตกต่างนี้ทำให้แก้ภาพโดยไม่ต้องสร้างสนามใหม่ และช่วยตรวจว่าการบันทึกแล้วเปิดซ้ำยังคงส่วนประกอบเดิม การนำเข้าภาพเป็นการใช้ไฟล์ที่ผู้ใช้เตรียมไว้ จึงไม่หมายถึงระบบวาดหรือตกแต่งภาพในตัว')
h('2.3 การพัฒนาแอปพลิเคชันด้วย Godot สำหรับเว็บ')
p('Godot Engine เป็นเครื่องมือที่ใช้พัฒนาโครงการนี้ร่วมกับภาษา GDScript เอกสารการส่งออกเว็บระบุว่าผลงานสามารถทำงานในเบราว์เซอร์ที่รองรับ WebAssembly และ WebGL 2.0 โดยใช้การเรนเดอร์แบบ Compatibility (Godot Engine, n.d.) การส่งออกเว็บเป็นขั้นตอนแยกจากการรันภายในเครื่องมือพัฒนา จึงต้องตรวจพฤติกรรมในเบราว์เซอร์จริง')
p('แอปบนเว็บอยู่ภายใต้ข้อจำกัดการเข้าถึงไฟล์และพื้นที่จัดเก็บของเบราว์เซอร์ การบันทึกในเครื่องอาจอยู่ในพื้นที่ของเว็บไซต์หรือไฟล์ที่ผู้ใช้ส่งออก วิธีเก็บข้อมูลจึงต้องสื่อให้เข้าใจว่าเปิดซ้ำได้ที่ใด และภาพที่ใช้อ้างอิงยังพร้อมใช้งานหรือไม่ ข้อจำกัดดังกล่าวมีผลโดยตรงต่อเครื่องมือที่ต้องนำเข้าภาพและเปิดต้นแบบเดิมกลับมาแก้ไข (Godot Engine, n.d.)')

page();h('2.4 การจัดเก็บข้อมูลและสิทธิ์ของผู้ใช้')
p('การจัดเก็บ local หมายถึงการเก็บข้อมูลฝั่งเครื่องที่ใช้งาน ส่วนการจัดเก็บออนไลน์ใช้บริการส่วนกลางเพื่อให้เรียกข้อมูลผ่านเครือข่ายได้ การมีข้อมูลออนไลน์เพียงอย่างเดียวไม่ได้ทำให้ทรัพยากรเป็นส่วนตัว ระบบยังต้องระบุว่าใครเป็นเจ้าของ และบัญชีใดสามารถอ่าน แก้ไข หรือลบข้อมูลนั้นได้')
p('Supabase ใช้ Row Level Security หรือ RLS กำหนดสิทธิ์ระดับแถว โดยใช้เงื่อนไขความเป็นเจ้าของจำกัดข้อมูลที่แต่ละบัญชีเข้าถึงได้ (Supabase, n.d.) จึงเป็นการตรวจสิทธิ์ที่บริการข้อมูล ไม่ใช่เพียงซ่อนรายการในหน้าจอ สำหรับ CratAble การแยกทรัพยากรตามบัญชียังเป็นขอบเขตที่จะพัฒนา')
h('2.5 การสื่อสารและสถานะร่วมในการเล่นออนไลน์')
p('การเล่นออนไลน์ต้องส่งข้อมูลระหว่างผู้เล่น เช่น การย้ายหรือพลิกการ์ด คะแนน และผลลูกเต๋า บริการ Supabase Realtime Broadcast รองรับการส่งข้อความระหว่างไคลเอนต์ผ่านช่องสื่อสาร (Supabase, 2026) โดยแอปยังต้องกำหนดว่าข้อความเป็นของห้องใด และเปลี่ยนข้อมูลวัตถุอย่างไร การมีช่องสื่อสารจึงไม่ได้รับรองว่าข้อมูลเกมถูกต้องโดยอัตโนมัติ')
p('สถานะร่วมหมายถึงข้อมูลที่ผู้เล่นควรเห็นตรงกัน เช่น จำนวนการ์ดในกอง ตำแหน่งบนโต๊ะ และค่าตัวนับ ส่วนมุมมองหน้าจออาจแตกต่างตามผู้ถือการ์ด การหันหน้าจอคนละทิศจึงไม่แปลว่าข้อมูลผิดเสมอไป ในทางกลับกัน ภาพที่ดูคล้ายกันก็ยังไม่รับรองว่าจำนวนหรือลำดับการ์ดตรงกัน การออกแบบจึงต้องแยกพิกัดบนโต๊ะออกจากมุมมอง และแยกข้อมูลสาธารณะออกจากหน้าการ์ดในมือที่ผู้เล่นอื่นไม่ควรเห็น')
p('ความถูกต้องกับความรวดเร็วเป็นคนละคุณสมบัติ ระบบอาจตอบสนองเร็วแต่ทำการ์ดซ้ำ หรือแสดงผลถูกต้องแต่ช้า การตรวจออนไลน์จึงต้องพิจารณาทั้งการสูญหายของคำสั่ง ความสอดคล้องของสถานะ และเวลาที่ผลปรากฏ การตรวจทางเทคนิคสามารถใช้ผู้จัดทำสองคนกับโน้ตบุ๊กสองเครื่องได้ โดยไม่จำเป็นต้องใช้กลุ่มผู้ทดลองจำนวนมาก')
h('2.6 การใช้งานได้และประสบการณ์ของผู้ใช้')
p('ISO 9241-11:2018 ให้กรอบพิจารณาการใช้งานของระบบภายใต้ผู้ใช้ เป้าหมาย และบริบทที่กำหนด (International Organization for Standardization [ISO], 2018) การประเมินจึงควรสนใจว่าผู้ใช้ทำสิ่งที่ต้องการได้หรือไม่ ใช้ความพยายามเพียงใด และมีประสบการณ์อย่างไร ความสวยงามของหน้าจอเป็นส่วนหนึ่งของประสบการณ์ แต่ไม่สามารถใช้แทนการตรวจว่าผู้ใช้ทำงานสำเร็จ')
p('Moran (2019) อธิบายการให้ผู้เข้าร่วมทำภารกิจจริง ขณะที่ผู้ดำเนินการสังเกตและรับฟังความคิดเห็น วิธีนี้ช่วยพบปัญหา เช่น หาปุ่มบันทึกไม่พบ ซึ่งคะแนนความพึงพอใจอย่างเดียวอาจไม่บอกสาเหตุ สำหรับโต๊ะที่ไม่กำหนดกติกา ความสนุกยังขึ้นกับผู้เล่น จึงควรแยกจากความง่ายของเครื่องมือ')

page();h('2.7 งานวิจัยที่เกี่ยวข้อง')
p('Steinböck (2017) ศึกษารูปแบบการออกแบบเกมการ์ดดิจิทัล จัดทำกลุ่มรูปแบบที่ใช้วิเคราะห์และออกแบบเกม และเสนอแบบจำลองนามธรรมของเกมการ์ดพร้อมต้นแบบ งานนี้เชื่อมมุมมองของผู้ออกแบบเกมกับโครงสร้างข้อมูลสำหรับผู้พัฒนา ประเด็นที่นำมาใช้กับ CratAble คือการแยกส่วนประกอบและการกระทำพื้นฐานให้ใช้ซ้ำได้ ขณะที่ขอบเขตของ CratAble ยังคงให้ผู้เล่นดำเนินกติกาเอง')
p('Sauro และ Dumas (2009) เปรียบเทียบแบบประเมินหลังภารกิจที่ใช้คำถามเดียวสามรูปแบบ โดยศึกษาการวัดความยากง่ายและความเหมาะสมในการใช้ งานนี้สนับสนุนการเก็บความคิดเห็นสั้น ๆ หลังภารกิจที่เพิ่งทำ แต่คะแนนดังกล่าวไม่ครอบคลุมความพึงพอใจต่อผลิตภัณฑ์ทุกด้าน')
p('Sauro และ Lewis (2024) อธิบายพัฒนาการของ Single Ease Question หรือ SEQ ซึ่งถามความยากง่ายหลังผู้ใช้พยายามทำภารกิจด้วยมาตรา 7 ระดับ การใช้คำถามสั้นช่วยลดภาระของผู้ตอบและเชื่อมความคิดเห็นกับงานแต่ละอย่างได้ชัดเจน หากนำมาใช้เป็นภาษาไทย ต้องตรวจความเข้าใจของคำแปล และไม่อ้างว่าเป็นแบบประเมินภาษาไทยที่ผ่านการรับรองเพียงเพราะอ้างอิงต้นฉบับ')
h('2.8 แนวคิดการประเมินต้นแบบด้วยผู้ใช้กลุ่มเล็ก')
p('การทดสอบเชิงคุณภาพมุ่งค้นหาว่าผู้ใช้ติดขัดตรงไหนและเพราะเหตุใด ส่วนการทดสอบเชิงปริมาณมุ่งประมาณตัวชี้วัดที่นำไปเปรียบเทียบหรืออ้างอิงในวงกว้าง จำนวนผู้เข้าร่วมจึงสัมพันธ์กับจุดประสงค์ ไม่ใช่มีจำนวนขั้นต่ำเดียวสำหรับทุกโครงงาน (Moran, 2019) การพัฒนาต้นแบบระยะแรกสามารถเริ่มด้วยการสังเกตผู้ใช้กลุ่มเล็กและแก้ปัญหาที่พบได้')
p('Nielsen (2000) เสนอให้แบ่งทรัพยากรเป็นการทดสอบขนาดเล็กแล้วปรับปรุงเป็นรอบ และกล่าวถึงการใช้ผู้เข้าร่วมประมาณ 3–4 คนต่อกลุ่มเมื่อมีผู้ใช้สองกลุ่ม แนวทางนี้เป็นเหตุผลรองรับการเก็บข้อมูลเพื่อค้นหาปัญหา ไม่ใช่หลักประกันว่าจะพบข้อผิดพลาดครบ หรือใช้กลุ่มเล็กแทนประชากรทั้งหมดได้ หากพบว่าปัญหายังหลากหลายหรือมีความเสี่ยงสำคัญ ต้องทดสอบเพิ่มเติมตามประเด็นนั้น')
p('การลดระยะเวลาสามารถทำได้โดยเลือกภารกิจหลักที่ครอบคลุมเส้นทางการใช้งาน เตรียมภาพและสนามเริ่มต้นไว้ และใช้คำถามหลังภารกิจแบบสั้น ส่วนการตรวจทุกฟังก์ชันและความเสถียรออนไลน์แยกเป็นงานของผู้จัดทำ วิธีนี้เป็นการประยุกต์แนวคิดข้างต้นให้เหมาะกับทรัพยากรของโครงงาน ระยะเวลาที่เลือกต้องซ้อมก่อนใช้งานจริง และรายงานเฉพาะขอบเขตที่ได้ตรวจ')
p('เอกสารที่ทบทวนเชื่อมองค์ประกอบเกม การเก็บข้อมูล การเล่นร่วมกัน และการใช้งานเข้าด้วยกัน จึงควรใช้หลักฐานจากผู้ใช้ร่วมกับการตรวจทางเทคนิคเพื่อปรับปรุงแพลตฟอร์ม โดยสรุปผลตามขอบเขตที่ตรวจจริง')

def ref(a,t,b):
    x=para('',indent=False);x.paragraph_format.left_indent=Cm(1.27);x.paragraph_format.first_line_indent=Cm(-1.27);x.paragraph_format.space_after=Pt(4)
    x.add_run(a);x.add_run(t).italic=True;x.add_run(b)
page();para('เอกสารอ้างอิงสำหรับบทที่ 2','Heading 1',center=True)
ref('Godot Engine. (n.d.). ','Exporting for the Web. ','Godot Engine documentation. Retrieved November 3, 2026, from https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html')
ref('International Organization for Standardization. (2018). ','Ergonomics of human-system interaction—Part 11: Usability: Definitions and concepts ','(ISO Standard No. 9241-11:2018). https://www.iso.org/standard/63500.html')
ref('Moran, K. (2019, December 1). ','Usability (user) testing 101. ','Nielsen Norman Group. https://www.nngroup.com/articles/usability-testing-101/')
ref('Nielsen, J. (2000, March 18). ','Why you only need to test with 5 users. ','Nielsen Norman Group. https://www.nngroup.com/articles/why-you-only-need-to-test-with-5-users/')
ref('Sauro, J., & Dumas, J. S. (2009). Comparison of three one-question, post-task usability questionnaires. In ','Proceedings of the SIGCHI Conference on Human Factors in Computing Systems ','(pp. 1599–1608). Association for Computing Machinery. https://doi.org/10.1145/1518701.1518946')
ref('Sauro, J., & Lewis, J. (2024, August 6). ','The evolution of the Single Ease Question (SEQ). ','MeasuringU. https://measuringu.com/evolution-of-seq/')
ref('Steinböck, M. (2017). ','Game design patterns in digital card games: A browser engine to an abstract card game model ','[Master’s thesis, Technische Universität Wien]. reposiTUm. https://doi.org/10.34726/hss.2017.51785')
ref('Supabase. (n.d.). ','Row level security. ','Retrieved November 3, 2026, from https://supabase.com/docs/guides/database/postgres/row-level-security')
ref('Supabase. (2026, October 23). ','Broadcast. ','https://supabase.com/docs/guides/realtime/broadcast')

# Keep Thai word wrapping stable when the recipient's Word lacks Thai proofing tools.
qa=ROOT/'qa';qa.mkdir(exist_ok=True)
textnodes=list(doc.element.iter(qn('w:t')))
inp=qa/'text.json';out=qa/'segmented.json'
inp.write_text(json.dumps([x.text or '' for x in textnodes],ensure_ascii=False),encoding='utf-8')
runtime='C:/Program Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1026-487-0_26.1026.487.0_x64__3k8sg7r9htsxt/dependencies/node/bin/node.exe'
js="const fs=require('fs');const seg=new Intl.Segmenter('th',{granularity:'word'});let a=JSON.parse(fs.readFileSync(process.argv[1],'utf8'));fs.writeFileSync(process.argv[2],JSON.stringify(a.map(s=>s.replace(/[\\u0E00-\\u0E7F]+/gu,t=>Array.from(seg.segment(t),x=>x.segment).join('\\u200B')))));"
subprocess.run([runtime,'-e',js,str(inp),str(out)],check=True)
for node,text in zip(textnodes,json.loads(out.read_text(encoding='utf-8'))):node.text=text
target=ROOT/'CratAble_บทที่2_ฉบับปรับปรุง.docx'
doc.save(target)
assert before==hashlib.sha256(SOURCE.read_bytes()).hexdigest()
(qa/'artifact.md').write_text(f'''# Chapter 2 revision
Source: {SOURCE}
Source SHA256: {before}
Narrow rewrite and extraction of chapter 2; source retained unchanged.
Format: A4; Angsana New 16 pt; single line spacing; top 1.5 inches and other margins 1 inch.
Reuse source Normal, Title and Heading styles. One section, page numbering starts at 1.
Chapter body target 3 pages; references 1 page. No chapters 1 or 3 and no results.
Revised focus: concepts and relevant findings; short qualitative evaluation is explained as a principle.
''',encoding='utf-8')
print(target)
