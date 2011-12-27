CC=g++
CFLAGS=-g3 -O0 -Wall
LFLAGS=-lopencv_core -lopencv_imgproc -lopencv_highgui

TRGS=HWClassifier
OBJS=main.o

HWClassifier: $(OBJS) HWRecognition.h
	$(CC) -o $@ $(OBJS) $(CFLAGS) $(LFLAGS)

main.o: main.cpp HWRecognition.h
	$(CC) -c $< $(CFLAGS)

clean:
	-rm -rf $(TRGS) $(OBJS)
