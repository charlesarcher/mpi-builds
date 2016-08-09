#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <mpi.h>

#if 0
#define MPI_Isend PMPI_Isend
#define MPI_Send PMPI_Send
#endif

#define TRACING_SSC_MARK( MARK_ID )     \
        __asm__ __volatile__ (          \
        "\n\t  movl $"#MARK_ID", %%ebx" \
        "\n\t  .byte 0x64, 0x67, 0x90"  \
        : : : "%ebx" );



#define ITERATIONS	(1)
#define SIZE		(4)
#define WINDOW		(64)

int main(int argc, char* argv[])
{
  int window = WINDOW, iterations = ITERATIONS, size = SIZE;
  int op, i, j, me, nprocs;
  char *sbuf, *rbuf;
  double t_start=0, t_end=0;
  MPI_Request *requests;

  int required = MPI_THREAD_MULTIPLE, provided;
  MPI_Init_thread(&argc, &argv, required,&provided);

  while ((op = getopt(argc, argv, "w:i:s:")) != -1) {
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
  fprintf(stderr, "Iterations  = %d window=%d s=%d\n", iterations, window, size);

  memset(sbuf, 'a', size*window);
  memset(sbuf, 'b', size*window);

  MPI_Barrier(MPI_COMM_WORLD);

  if (0 == me) {
    MPI_Isend(sbuf, size,
             MPI_CHAR, 1, 222,
             MPI_COMM_WORLD,
             &requests[0]);
    MPI_Irecv(rbuf, size,
              MPI_CHAR, 1, 222,
              MPI_COMM_WORLD,
              &requests[1]);
    MPI_Waitall(2, requests, MPI_STATUSES_IGNORE);

    MPI_Barrier(MPI_COMM_WORLD);
    for(i=0; i<iterations; i++) {
      MPI_Barrier(MPI_COMM_WORLD);
      for(j=0; j<window; j++) {
        t_start = MPI_Wtime();
        if(i==1)
          TRACING_SSC_MARK(0x200);
#ifdef USE_ISEND
#pragma forceinline
        MPI_Isend((void *) &sbuf[j*size], size,
                  MPI_CHAR, 1, 222,
                  MPI_COMM_WORLD,
                  &requests[j]);
#else
#pragma forceinline
        MPI_Send((void *) &sbuf[j*size], size,
                  MPI_CHAR, 1, 222,
                  MPI_COMM_WORLD);
#endif
        if(i==1)
          TRACING_SSC_MARK(0x210);
        t_end = MPI_Wtime();
      }
#ifdef USE_ISEND
        if(i==1)
                TRACING_SSC_MARK(0x220);
#pragma forceinline
        MPI_Waitall(window, requests, MPI_STATUSES_IGNORE);
        if(i==1)
                TRACING_SSC_MARK(0x240);
#endif
    }
  } else if (1 == me) {
    {
      int flag=1;
      fprintf(stderr, "MPI_Isend %p\n", MPI_Isend);
      while(!flag);
    }
    MPI_Isend(sbuf, size,
              MPI_CHAR, 0, 222,
              MPI_COMM_WORLD,
              &requests[0]);
    MPI_Irecv(rbuf, size,
              MPI_CHAR, 0, 222,
              MPI_COMM_WORLD,
              &requests[1]);
    MPI_Waitall(2, requests, MPI_STATUSES_IGNORE);
    fprintf(stderr, "got 30 more seconds\n");
    fprintf(stderr, "continuing\n");
    MPI_Barrier(MPI_COMM_WORLD);
    int first=0;
    for(i=0; i<iterations; i++) {
#ifndef USE_IRECV
      MPI_Barrier(MPI_COMM_WORLD);
#endif
      for(j=0; j<window; j++) {

        if(i==1)
                TRACING_SSC_MARK(0x260);
#ifdef USE_IRECV
#pragma forceinline
        MPI_Irecv((void *) &rbuf[j*size], size,
                  MPI_CHAR, 0, 222,
                  MPI_COMM_WORLD,
                  &requests[j]);
#else
#pragma forceinline
        MPI_Recv((void *) &rbuf[j*size], size,
                 MPI_CHAR, 0, 222,
                 MPI_COMM_WORLD,
                 MPI_STATUS_IGNORE);
#endif
        if(i==1)
                TRACING_SSC_MARK(0x280);

      }
#ifdef USE_IRECV
      MPI_Barrier(MPI_COMM_WORLD); // ensures receives are posted before sends
      if(i==1)
              TRACING_SSC_MARK(0x300);
#pragma forceinline
      MPI_Waitall(window, requests, MPI_STATUSES_IGNORE);
      if(i==1)
              TRACING_SSC_MARK(0x310);
#endif
    }
  } else {
    fprintf(stderr, "This test requires exactly two processes.\n");
    exit(EXIT_FAILURE);
  }

  MPI_Barrier(MPI_COMM_WORLD);

  printf("[%d] Test ending PID %d time %0.3g\n", me, getpid(), (t_end-t_start));

  free(sbuf);
  free(rbuf);
  free(requests);

  MPI_Finalize();
  return 0;
}
