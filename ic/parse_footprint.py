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
cell_list_ld  = nesteddict()
cell_list_st  = nesteddict()
cell_list_ldst= nesteddict()
cell_list_code= nesteddict()
wb            = xlsxwriter.Workbook('footprint.xlsx')
q             = Q.PriorityQueue()
global val
val = 0

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
#            if len(x)>1 and x[0] == '--' and x[1]=="0":
#                print x
    def output(self):
        sheetidx[self.wsname][0]=0
        ws = worksheets[self.wsname]
        ws.write(sheetidx[self.wsname][0],sheetidx[self.wsname][1], "%s"%(self.seriesname))
        sheetidx[self.wsname][0]=sheetidx[self.wsname][0]
#        print self.seriesname,self.wsname,sheetidx[self.wsname][0],sheetidx[self.wsname][1]
        r=sheetidx[self.wsname][0]+1
        c=sheetidx[self.wsname][1]
        for line in self.lines:
            x = line.strip().split()
            if len(x)>1 and x[0] == '--' and x[1]=="0":
#                print r, c, x, len(x)
                ws.write(r+0,c,"LD")
                ws.write(r+1,c,"ST")
                ws.write(r+2,c,"LDST")
                ws.write(r+3,c,"CODE")
                ws.write(r+4,c,"TOTAL")
                ws.write_number(r+0,c+1,int(x[2]))
                a=xl_rowcol_to_cell(r+0,c+1)
                cell_list_ld[self.wsname].append(a)
                ws.write_number(r+1,c+1,int(x[3]))
                a=xl_rowcol_to_cell(r+1,c+1)
                cell_list_st[self.wsname].append(a)
                ws.write_number(r+2,c+1,int(x[4]))
                a=xl_rowcol_to_cell(r+2,c+1)
                cell_list_ldst[self.wsname].append(a)
                ws.write_number(r+3,c+1,int(x[5]))
                a=xl_rowcol_to_cell(r+3,c+1)
                cell_list_code[self.wsname].append(a)
                ws.write_number(r+4,c+1,int(x[9]))
        sheetidx[self.wsname][1]=sheetidx[self.wsname][1]+3

subdir='sdelog.bak'
os.chdir(subdir)
os.listdir(os.curdir)
val        = 0
extensions = ['footprint' ] ;
file_names = [fn for fn in os.listdir(os.curdir) if any([fn.endswith(ext) for ext in extensions])];
for file in file_names:
    print file
benchmarks = [Benchmark(file) for file in file_names]
names = ['isend|gnu',   'send|gnu'  ,'put|gnu'  ,'putsync|gnu'  ,  'sendwait|gnu'  ,'recvwait|gnu','irecv|gnu',  'recv|gnu',
         'isend|intel', 'send|intel','put|intel','putsync|intel','sendwait|intel','recvwait|intel','irecv|intel','recv|intel',
         'isend|clang', 'send|clang','put|clang','putsync|clang','sendwait|clang','recvwait|clang','irecv|clang','recv|clang',
          ]

for name in names:
    worksheets[name]    = wb.add_worksheet(name)
    column_charts[name] = wb.add_chart({'type': 'column', 'subtype': 'stacked'})
    worksheets[name].insert_chart('A9',column_charts[name])
    sheetidx[name]      = [0,0]

for bm in benchmarks:
    bm.output()

for name in names:
#    print name
#    print "CELL LIST", cell_list_ld[name]
#    values='=(Sheet1!$B$1:$B$9,Sheet1!$B$14:$B$25)'
#    print "EXAMPLE", values
    arrays = [["load",cell_list_ld[name]],
              ["store",cell_list_st[name]],
              ["load/store",cell_list_ldst[name]],
              ["code",cell_list_code[name]]]
    for array in arrays:
        i=0
        values='=('
        categories='=('
        cell=0
        for ldname in array[1]:
            if i != 0:
                values+=','
                categories+=','
            values+='\'%s\'!%s:%s'%(name,ldname,ldname)
            a=xl_rowcol_to_cell(0,cell)
            categories+='\'%s\'!%s:%s'%(name,a,a)
            cell=cell+3
            i=i+1
        values+=')'
        categories+=')'
#        print "VALUES", values
#        print bm.wsname,sheetidx[bm.wsname][0],sheetidx[bm.wsname][1],sheetidx[bm.wsname][0],sheetidx[bm.wsname][1]
#        print categories
        series = {
            'name':array[0],
#            'categories': [bm.wsname, sheetidx[bm.wsname][0],sheetidx[bm.wsname][1],sheetidx[bm.wsname][0],sheetidx[bm.wsname][1]],
            'categories': categories,
            'values':     values,
            'data_labels': {'value': True, 'legend_key': True},
            'marker': {'type': 'automatic'},
        }
#        print name, "adding series", series
        q.put((val, name, series))
        val=val+1

while not q.empty():
    series = q.get()
    print "adding series", series
    column_charts[series[1]].add_series(series[2])
    column_charts[series[1]].set_size({'width': 1280, 'height': 640})
    column_charts[series[1]].set_title({'name': series[1]})
    column_charts[series[1]].set_x_axis({
        'name': "MPI Flavor",
        'text_axis': True,
        'num_font':  {'rotation': 270}
    })
    column_charts[series[1]].set_y_axis({
        'name': "Footprint (Cache line touches)"
    })

wb.close()
