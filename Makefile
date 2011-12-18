ROOT=/home/mhr2126/HWRecognition

CC=g++
CFLAGS=-g3 -O0 -Wall -I$(ROOT)/opencv2/include
LFLAGS=-L$(ROOT)/opencv2/lib -lopencv_core -lopencv_highgui

OBJS=main.o

HWClassifier: $(OBJS)
	$(CC) -o $@ $(OBJS) $(CFLAGS) $(LFLAGS)

main.o: main.cpp
	$(CC) -c $< $(CFLAGS)

clean:
	-rm -rf $(OBJS)
