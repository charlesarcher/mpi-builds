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
column_charts = {}
wb = xlsxwriter.Workbook('instructions.xlsx')
q = Q.PriorityQueue()

class Benchmark:
    def __init__(self, name):
        self.name         = name
        self.module_count = defaultdict(lambda: 0)
        self.symbol_count = defaultdict(lambda: 0)
        namesplit=self.name.split('.')
        self.wsname = namesplit[0] + '|' + namesplit[1]
        self.seriesname = namesplit[3] + '|' + namesplit[2]

        for line in open(file, 'r'):
            if re.search(' INS ',line.strip()):
                x = line.strip().split()[3].split('+')[0]
                xsplit=x.split(':')
                y = xsplit[0]
                if len(xsplit) == 1:
                    x="SYSCALL:UNKNOWN"
                    y="SYSCALL"
                self.symbol_count[x] += 1
                self.module_count[y] += 1
        for x in sorted(self.module_count, key=self.module_count.get, reverse=True):
            self.d2 = dict((k, v) for k, v in self.symbol_count.items() if re.search(x, k))
    def output(self):
        sheetidx[self.wsname][0]=0
        ws = worksheets[self.wsname]
        ws.write(sheetidx[self.wsname][0],sheetidx[self.wsname][1], "%s"%(self.seriesname))
        sheetidx[self.wsname][0]=sheetidx[self.wsname][0]+1
        celllist =[]
        sum=0
        print self.seriesname
        for x in sorted(self.module_count, key=self.module_count.get, reverse=True):
            ws.write(sheetidx[self.wsname][0],sheetidx[self.wsname][1], "%s"%(x))
            sheetidx[self.wsname][0]=sheetidx[self.wsname][0]+1
            self.d2 = dict((k, v) for k, v in self.symbol_count.items() if re.search(x, k))
            a=xl_rowcol_to_cell(sheetidx[self.wsname][0], sheetidx[self.wsname][1]+2)
            for y in sorted(self.d2, key=self.d2.get, reverse=True):
                ws.write(sheetidx[self.wsname][0],sheetidx[self.wsname][1]+1, "%s"%(y.split(":")[1]))
                ws.write_number(sheetidx[self.wsname][0],sheetidx[self.wsname][1]+2, int(str(self.symbol_count[y])))
                sum = sum + int(str(self.symbol_count[y]))
                sheetidx[self.wsname][0]=sheetidx[self.wsname][0]+1
            b=xl_rowcol_to_cell(sheetidx[self.wsname][0]-1, sheetidx[self.wsname][1]+2)
            c=xl_rowcol_to_cell(sheetidx[self.wsname][0], sheetidx[self.wsname][1]+2)
            celllist.append(c)
            ws.write_formula(sheetidx[self.wsname][0],sheetidx[self.wsname][1]+2, "=SUM(%s:%s)"%(a,b))
            ws.write(sheetidx[self.wsname][0],sheetidx[self.wsname][1]+1, "SubTotal:")
            sheetidx[self.wsname][0]=sheetidx[self.wsname][0]+1

        cellstr=""
        first=1
        for cell in celllist:
            if first:
                cellstr=cellstr + cell
                first=0
            else:
                cellstr=cellstr + "," +cell
        if(len(cellstr)):
            ws.write_formula(sheetidx[self.wsname][0],sheetidx[self.wsname][1]+2, "=SUM(%s)"%(cellstr))
            ws.write(sheetidx[self.wsname][0],sheetidx[self.wsname][1]+1, "Total")
            series = {
                'name':self.seriesname,
                'categories': [self.wsname, sheetidx[self.wsname][0],sheetidx[self.wsname][1]+2,sheetidx[self.wsname][0],sheetidx[self.wsname][1]+2],
                'values':     [self.wsname, sheetidx[self.wsname][0],sheetidx[self.wsname][1]+2,sheetidx[self.wsname][0],sheetidx[self.wsname][1]+2],
                'data_labels': {'value': True, 'legend_key': True},
                'marker': {'type': 'automatic'},
            }
#            column_charts[self.wsname].add_series(series)
            q.put((-sum, self.wsname, series))
        sheetidx[self.wsname][1]=sheetidx[self.wsname][1]+3

subdir='sdelog.bak'
os.chdir(subdir)
os.listdir(os.curdir)

extensions = ['filtered' ] ;
file_names = [fn for fn in os.listdir(os.curdir) if any([fn.endswith(ext) for ext in extensions])];
benchmarks = [Benchmark(file) for file in file_names]
names = ['isend|gnu',   'send|gnu',  'put|gnu'  ,'putsync|gnu'  ,'sendwait|gnu'  ,'recvwait|gnu','irecv|gnu',  'recv|gnu',
         'isend|intel', 'send|intel','put|intel','putsync|intel','sendwait|intel','recvwait|intel','irecv|intel','recv|intel',
         'isend|clang', 'send|clang','put|clang','putsync|clang','sendwait|clang','recvwait|clang','irecv|clang','recv|clang',
          ]

for name in names:
    worksheets[name]    = wb.add_worksheet(name)
    column_charts[name] = wb.add_chart({'type': 'column'})
    worksheets[name].insert_chart('A30',column_charts[name])
    sheetidx[name]      = [0,0]

for bm in benchmarks:
    bm.output()

while not q.empty():
    series = q.get()
    column_charts[series[1]].add_series(series[2])
    column_charts[series[1]].set_size({'width': 1280, 'height': 640})
    column_charts[series[1]].set_title({'name': series[1]})
    column_charts[series[1]].set_x_axis({
        'name': "MPI Optimization",
    })
    column_charts[series[1]].set_y_axis({
        'name': "Instruction Count"
    })



wb.close()
