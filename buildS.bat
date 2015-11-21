asm86 188tievh.asm m1 ep db
asm86 d2str.asm m1 ep db
asm86 disp14.asm m1 ep db
asm86 h2str.asm m1 ep db
asm86 initcs.asm m1 ep db
asm86 inittmr.asm m1 ep db
asm86 keypad.asm m1 ep db
asm86 queue.asm m1 ep db
asm86 segtab14.asm m1 ep db
asm86 serial.asm m1 ep db
asm86 srlprs.asm m1 ep db
asm86 motor.asm m1 ep db
asm86 slvui.asm m1 ep db
asm86 trigtbl.asm m1 ep db
asm86 slave.asm m1 ep db
link86 disp14.obj,d2str.obj,h2str.obj,keypad.obj,queue.obj,segtab14.obj,188tievh.obj,initcs.obj,inittmr.obj to c.lnk
link86 slave.obj,slvui.obj,motor.obj,serial.obj,trigtbl.obj,srlprs.obj to d.lnk
link86 c.lnk,d.lnk to mainS.lnk
loc86 mainS.lnk NOIC AD(SM(CODE(1000H),DATA(400H),STACK(7000H)))