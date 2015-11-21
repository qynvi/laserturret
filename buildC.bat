asm86 188tievh.asm m1 ep db
asm86 command.asm m1 ep db
asm86 comUI.asm m1 ep db
asm86 d2str.asm m1 ep db
asm86 disp14.asm m1 ep db
asm86 h2str.asm m1 ep db
asm86 initcs.asm m1 ep db
asm86 inittmr.asm m1 ep db
asm86 keypad.asm m1 ep db
asm86 queue.asm m1 ep db
asm86 segtab14.asm m1 ep db
asm86 serial.asm m1 ep db
link86 disp14.obj,d2str.obj,h2str.obj,keypad.obj,queue.obj,segtab14.obj to a.lnk
link86 188tievh.obj,command.obj,comui.obj,initcs.obj,inittmr.obj,serial.obj to b.lnk
link86 a.lnk,b.lnk to mainC.lnk
loc86 mainC.lnk NOIC AD(SM(CODE(1000H),DATA(400H),STACK(7000H)))