MAPS = qinv1.bsp

AMBIENT = 50

LIGHTFLAGS = -ambientlight $(AMBIENT)

%.bsp: %.map
	@echo "Compiling map $<..."
	hmap2 $< # compile bsp
	hmap2 -vis $@ # vis
	hmap2 -light -extra $(LIGHTFLAGS) $@ # light

maps: $(MAPS)
