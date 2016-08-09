#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <mpi.h>
/*#include <simics/magic-instruction.h>*/
#include "/opt/simics/simics-4.8/simics-4.8.99/src/include/simics/magic-instruction.h"
#define ITERATIONS	(1000)
#define SIZE		(8)
#define WINDOW		(64)


int main(int argc, char* argv[])
{
	int window = WINDOW, iterations = ITERATIONS, size = SIZE;
	int op, i, j, me, nprocs, trace=0;
	char *sbuf, *rbuf;
	MPI_Request *requests;

	MPI_Init(&argc, &argv);

	while ((op = getopt(argc, argv, "w:i:s:t:")) != -1) {
		switch (op) {
			case 'w':
				window = atoi(optarg);
				break;
			case 'i':
				iterations = atoi(optarg);
				break;
			case 's':
				size = atoi(optarg);
				break;
			case 't':
				trace = atoi(optarg);
				break;
			default:
				printf("usage: %s\n", argv[0]);
				printf("\t[-w window size (default %d)]\n", WINDOW);
				printf("\t[-i iterations (default %d)]\n", ITERATIONS);
				printf("\t[-s message size (default %d)]\n", SIZE);
				exit(1);
		}
	}

	MPI_Comm_rank(MPI_COMM_WORLD, &me);
	MPI_Comm_size(MPI_COMM_WORLD, &nprocs);

	MPI_Barrier(MPI_COMM_WORLD);

	if (posix_memalign((void **) &sbuf, getpagesize(), size*window)) {
		fprintf(stderr, "no memory\n");
		exit(EXIT_FAILURE);
	}
	if (posix_memalign((void **) &rbuf, getpagesize(), size*window)) {
		fprintf(stderr, "no memory\n");
		exit(EXIT_FAILURE);
	}

	requests = (MPI_Request *) malloc(sizeof(MPI_Request) * window);
	if (!requests) {
		fprintf(stderr, "no memory for requests\n");
		exit(EXIT_FAILURE);
	}

	memset(sbuf, 'a', size*window);
	memset(sbuf, 'b', size*window);

	MPI_Barrier(MPI_COMM_WORLD);

	if (0 == me) {
		MPI_Isend((void *) &sbuf[0], size, 
				MPI_CHAR, 1, 222,
				MPI_COMM_WORLD, 
				&requests[0]);
		MPI_Waitall(1, requests, MPI_STATUSES_IGNORE);

		for(i=0; i<iterations; i++) {
			if (trace)
				MAGIC(1);
			for(j=0; j<window; j++) {
				MPI_Isend((void *) &sbuf[j*size], size, 
						MPI_CHAR, 1, 222,
						MPI_COMM_WORLD, 
						&requests[j]);
			}
			if (trace)
				MAGIC(2);
			MPI_Waitall(window, requests, MPI_STATUSES_IGNORE);
		}
	} else if (1 == me) {
		MPI_Irecv((void *) &rbuf[0], size, 
				MPI_CHAR, 0, 222, 
				MPI_COMM_WORLD, 
				&requests[0]);
		MPI_Waitall(1, requests, MPI_STATUSES_IGNORE);
		for(i=0; i<iterations; i++) {
			for(j=0; j<window; j++) {
				MPI_Irecv((void *) &rbuf[j*size], size, 
						MPI_CHAR, 0, 222, 
						MPI_COMM_WORLD, 
						&requests[j]);
			}
			MPI_Waitall(window, requests, MPI_STATUSES_IGNORE);
		}
	} else {
		fprintf(stderr, "This test requires exactly two processes.\n");
		exit(EXIT_FAILURE);
	}

	MPI_Barrier(MPI_COMM_WORLD);

	printf("[%d] Test ending PID %d\n", me, getpid());

	getchar();
	free(sbuf);
	free(rbuf);
	free(requests);

	MPI_Finalize();

	return 0;
}
