import os,re,types,math
import xlsxwriter
import Queue as Q
from xlsxwriter.utility import xl_rowcol_to_cell
from collections import defaultdict

def nesteddict():
    return defaultdict(list)

benchmarks    = []
sheetidx      = {}
worksheets    = {}
wb            = xlsxwriter.Workbook('instruction_trace.xlsx')
q             = Q.PriorityQueue()

class Benchmark:
    def __init__(self, name):
        self.name         = name
        self.module_count = defaultdict(lambda: 0)
        self.symbol_count = defaultdict(lambda: 0)
        namesplit=self.name.split('.')
        self.wsname = namesplit[0] + '|' + namesplit[1]
        self.seriesname = namesplit[3] + '|' + namesplit[2]
        self.lines = open(file, 'r')
#        for line in self.lines:
#            x = line.strip().split()
#            print x
    def output(self):
        sheetidx[self.wsname][0]=0
        ws = worksheets[self.wsname]
        ws.write(sheetidx[self.wsname][0],sheetidx[self.wsname][1], "%s"%(self.seriesname))
        sheetidx[self.wsname][0]=sheetidx[self.wsname][0]+1
        print self.seriesname,self.wsname,sheetidx[self.wsname][0],sheetidx[self.wsname][1]
        r=sheetidx[self.wsname][0]
        c=sheetidx[self.wsname][1]
        for line in self.lines:
            x = line.strip().split()
            print r, c, x, len(x)
            if len(x) == 3:
                ws.write(r,c,x[0])
                ws.write(r,c+1,x[1])
                try:
                    int(x[2])
                    ws.write_number(r,c+2,int(x[2]))
                except ValueError:
                    ws.write(r,c+2,x[2])
                r=r+1
            if len(x) == 5:
                ws.write_number(r,c+1,int(x[3]))
                r=r+1
        sheetidx[self.wsname][1]=sheetidx[self.wsname][1]+3

subdir='ic'
os.chdir(subdir)
os.listdir(os.curdir)

extensions = ['ic' ] ;
file_names = [fn for fn in os.listdir(os.curdir) if any([fn.endswith(ext) for ext in extensions])];
benchmarks = [Benchmark(file) for file in file_names]
names = ['isend|gnu',   'send|gnu'  ,'put|gnu'  ,'putsync|gnu'  ,  'sendwait|gnu'  ,'recvwait|gnu','irecv|gnu',  'recv|gnu',
         'isend|intel', 'send|intel','put|intel','putsync|intel','sendwait|intel','recvwait|intel','irecv|intel','recv|intel',
         'isend|clang', 'send|clang','put|clang','putsync|clang','sendwait|clang','recvwait|clang','irecv|clang','recv|clang',
          ]
for name in names:
    worksheets[name]    = wb.add_worksheet(name)
    sheetidx[name]      = [0,0]

for bm in benchmarks:
    bm.output()

wb.close()
