import sys,os,re,types,math
import xlsxwriter
from collections import defaultdict

def nesteddict():
    return defaultdict(list)

benchmarks=defaultdict(list)
benchmarks_data=defaultdict(nesteddict)
benchmarks_func=defaultdict(types.FunctionType)

if len(sys.argv) < 2:
    sys.exit('Usage: %s plotdir' % sys.argv[0])

if not os.path.exists(sys.argv[1]):
    sys.exit('ERROR: plotdir %s was not found!' % sys.argv[1])

subdir=sys.argv[1]

wb = xlsxwriter.Workbook("osu-%s.xlsx"%(os.path.basename(subdir)))

class Parser:
    def plot_bandwidth (self, ws, bm_name):
        r = 0
        c = 0
        max_points = 22
        ws.write(1, 0, "%s"%("Size"))
        for x in range(2, max_points+2):
            ws.write(2+x-2, 0, math.pow(2,x-2))
        scatter_chart = wb.add_chart({'type': 'scatter', 'subtype':'straight_with_markers'})
        column_chart  = wb.add_chart({'type': 'column', 'subtype':'clustered'})
        c=1
        for platform in benchmarks[bm_name]:
            print platform
            r = 0
            ws.write(r,c, "%s"%(platform))
            r = 1
            ws.write(r,c,"%s (%ss)"%("Bandwidth", "MB/s"))
            r = 2
            start=(r,c)
            end=(r,c)
            end_bw=(r,c)
            parse_lines=max_points
            end_latency_parse=11
            for line in benchmarks_data[bench][platform][1:]:
                if parse_lines==0:
                    continue
                parse_lines=parse_lines-1
                if line.strip()!='':
                    work=line.split()
                    ws.write_number(r,c,float(work[1]))
                    if r <= end_latency_parse:
                        end=(r,c)
                    if r <= max_points+1:
                        end_bw=(r,c)
                r = r + 1
            c=c+1
            startx=(2,0)
            endx=(1+max_points,0)
            endx_bw=(1+max_points,0)

            column_chart.set_title({'name': bench})
            column_chart.add_series({
                'name':platform,
                'categories': [bm_name, startx[0], startx[1], endx[0], endx[1]],
                'values':     [bm_name, start[0], start[1], end[0], end[1]],
                'marker': {'type': 'automatic'},
            })
            column_chart.set_x_axis({
                'name': "Message Size (bytes)",
            })
            column_chart.set_y_axis({
                'name': "Bandwidth MB/s",
                })
            scatter_chart.set_title({'name': bench})
            scatter_chart.add_series({
                'name':platform,
                'categories': [bm_name, startx[0], startx[1], endx_bw[0], endx_bw[1]],
                'values':     [bm_name, start[0], start[1], end_bw[0], end_bw[1]],
                'marker': {'type': 'automatic'},
            })
            scatter_chart.set_x_axis({
                'name': "Message Size (bytes)",
                'log_base': 2,
            })
            scatter_chart.set_y_axis({
                'name': "Bandwidth MB/s",
                })
            column_chart.set_size({'width': 640, 'height': 360})
            scatter_chart.set_size({'width': 640, 'height': 360})
        ws.insert_chart('M1',column_chart)
        ws.insert_chart('M20',scatter_chart)
        return ' plot_bw  : Parsed'
    def plot_latency (self, ws, bm_name, start_point=0, max_points=8):
        r = 0
        c = 0
        ws.write(1, 0, "%s"%("Size"))
        ws.write(2, 0, start_point)
        if start_point == 0:
            start_idx = 1
        else:
            start_idx = int(math.log(start_point, 2))
        for x in range(start_idx, max_points):
            ws.write(2+x, 0, math.pow(2,x-1))

        scatter_chart = wb.add_chart({'type': 'scatter', 'subtype':'straight_with_markers'})
        column_chart  = wb.add_chart({'type': 'column', 'subtype':'clustered'})
        c=1
        for platform in benchmarks[bm_name]:
            print platform
            r = 0
            ws.write(r,c, "%s"%(platform))
            r = 1
            ws.write(r,c,"%s (%ss)"%("Latency", u"\u00b5"))
            r = 2
            start=(r,c)
            end=(r,c)
            parse_lines=max_points
            for line in benchmarks_data[bench][platform][1:]:
                if parse_lines==0:
                    continue
                parse_lines=parse_lines-1
                if line.strip()!='':
                    work=line.split()
                    ws.write_number(r,c,float(work[1]))
                    end=(r,c)
                r = r + 1
            c=c+1
            startx=(2,0)
            endx=(1+max_points,0)
            column_chart.set_title({'name': bench})
            column_chart.add_series({
                'name':platform,
                'categories': [bm_name, startx[0], startx[1], endx[0], endx[1]],
                'values':     [bm_name, start[0], start[1], end[0], end[1]],
                'marker': {'type': 'automatic'},
            })
            column_chart.set_x_axis({
                'name': "Message Size (bytes)",
            })
            column_chart.set_y_axis({
                'name': "Latency %ss"%(u"\u00b5"),
                })
            scatter_chart.set_title({'name': bench})
            scatter_chart.add_series({
                'name':platform,
                'categories': [bm_name, startx[0], startx[1], endx[0], endx[1]],
                'values':     [bm_name, start[0], start[1], end[0], end[1]],
                'marker': {'type': 'automatic'},
            })
            scatter_chart.set_x_axis({
                'name': "Message Size (bytes)",
            })
            scatter_chart.set_y_axis({
                'name': "Latency %ss"%(u"\u00b5"),
                })
            column_chart.set_size({'width': 640, 'height': 360})
            scatter_chart.set_size({'width': 640, 'height': 360})
        ws.insert_chart('M1',column_chart)
        ws.insert_chart('M20',scatter_chart)
        return 'plot latency  : Parsed'
    def plot_collective (self, ws, coll_name):
        r = 0
        c = 0
        max_points = 21
        ws.write(1, 0, "%s"%("Size"))
        for x in range(0, max_points):
            ws.write(2+x, 0, math.pow(2,x))
        scatter_chart = wb.add_chart({'type': 'scatter', 'subtype':'straight_with_markers'})
        column_chart  = wb.add_chart({'type': 'column', 'subtype':'clustered'})
        scatter_chart_bw = wb.add_chart({'type': 'scatter', 'subtype':'straight_with_markers'})
        c=1
        for platform in benchmarks[coll_name]:
            print platform
            r = 0
            ws.write(r,c, "%s"%(platform))
            r = 1
            ws.write(r,c,"%s (%ss)"%("Latency", u"\u00b5"))
            r = 2
            start=(r,c)
            end=(r,c)
            end_bw=(r,c)
            parse_lines=max_points
            end_latency_parse=8
            for line in benchmarks_data[bench][platform][2:]:
                if parse_lines==0:
                    continue
                parse_lines=parse_lines-1
                if line.strip()!='':
                    work=line.split()
                    ws.write_number(r,c,float(work[1]))
                    if r <= end_latency_parse:
                        end=(r,c)
                    if r <= max_points:
                        end_bw=(r,c)
                r = r + 1
            c=c+1
            startx=(2,0)
            endx=(2+end_latency_parse,0)
            endx_bw=(2+max_points,0)
            column_chart.set_title({'name': bench})
            column_chart.add_series({
                'name':platform,
                'categories': [coll_name, startx[0], startx[1], endx[0], endx[1]],
                'values':     [coll_name, start[0], start[1], end[0], end[1]],
                'marker': {'type': 'automatic'},
            })
            column_chart.set_x_axis({
                'name': "Message Size (bytes)",
            })
            column_chart.set_y_axis({
                'name': "Latency %ss"%(u"\u00b5"),
                })
            scatter_chart.set_title({'name': bench})
            scatter_chart.add_series({
                'name':platform,
                'categories': [coll_name, startx[0], startx[1], endx[0], endx[1]],
                'values':     [coll_name, start[0], start[1], end[0], end[1]],
                'marker': {'type': 'automatic'},
            })
            scatter_chart.set_x_axis({
                'name': "Message Size (bytes)",
            })
            scatter_chart.set_y_axis({
                'name': "Latency %ss"%(u"\u00b5"),
                })
            scatter_chart_bw.set_title({'name': bench})
            scatter_chart_bw.add_series({
                'name':platform,
                'categories': [coll_name, startx[0], startx[1], endx_bw[0], endx_bw[1]],
                'values':     [coll_name, start[0], start[1], end_bw[0], end_bw[1]],
                'marker': {'type': 'automatic'},
            })
            scatter_chart_bw.set_x_axis({
                'name': "Message Size (bytes)",
                'log_base': 2,
            })
            scatter_chart_bw.set_y_axis({
                'name': "Latency %ss"%(u"\u00b5"),
                'log_base': 2,
                })

            column_chart.set_size({'width': 640, 'height': 360})
            scatter_chart.set_size({'width': 640, 'height': 360})
            scatter_chart_bw.set_size({'width': 640, 'height': 360})
        ws.insert_chart('M1',column_chart)
        ws.insert_chart('M20',scatter_chart)
        ws.insert_chart('M40',scatter_chart_bw)
        return 'collective'
    def plot_icollective (self, ws, coll_name):
        r = 0
        c = 0
        max_points = 21
        ws.write(1, 0, "%s"%("Size"))
        for x in range(0, max_points):
            ws.write(2+x, 0, math.pow(2,x))
        scatter_chart = wb.add_chart({'type': 'scatter', 'subtype':'straight_with_markers'})
        column_chart  = wb.add_chart({'type': 'column', 'subtype':'clustered'})
        scatter_chart_bw = wb.add_chart({'type': 'scatter', 'subtype':'straight_with_markers'})
        column_chart_overlap  = wb.add_chart({'type': 'column', 'subtype':'clustered'})
        c=1
        for platform in benchmarks[coll_name]:
            print platform
            r = 0
            ws.write(r,c, "%s"%(platform))
            r = 1
            ws.write(r,c,"%s (%ss)"%("Latency", u"\u00b5"))
            ws.write(r,c+1,"%s"%("Overlap %"))
            r = 2
            start=(r,c)
            end=(r,c)
            end_bw=(r,c)
            end_overlap=(r,c+1)
            start_overlap=(r,c+1)
            parse_lines=max_points
            end_latency_parse=8
            for line in benchmarks_data[bench][platform][3:]:
                if parse_lines==0:
                    continue
                parse_lines=parse_lines-1
                if line.strip()!='':
                    work=line.split()
                    ws.write_number(r,c,float(work[3]))
                    ws.write_number(r,c+1,float(work[4]))
                    if r <= end_latency_parse+1:
                        end=(r,c)
                    if r <= max_points+1:
                        end_bw=(r,c)
                        end_overlap=(r,c+1)
                r = r + 1
            c=c+2
            startx=(2,0)
            endx=(1+end_latency_parse,0)
            endx_bw=(1+max_points,0)
            endx_overlap=(1+max_points,0)
            column_chart.set_title({'name': bench})
            column_chart.add_series({
                'name':platform,
                'categories': [coll_name, startx[0], startx[1], endx[0], endx[1]],
                'values':     [coll_name, start[0], start[1], end[0], end[1]],
                'marker': {'type': 'automatic'},
            })
            column_chart.set_x_axis({
                'name': "Message Size (bytes)",
            })
            column_chart.set_y_axis({
                'name': "Latency %ss"%(u"\u00b5"),
                })
            scatter_chart.set_title({'name': bench})
            scatter_chart.add_series({
                'name':platform,
                'categories': [coll_name, startx[0], startx[1], endx[0], endx[1]],
                'values':     [coll_name, start[0], start[1], end[0], end[1]],
                'marker': {'type': 'automatic'},
            })
            scatter_chart.set_x_axis({
                'name': "Message Size (bytes)",
            })
            scatter_chart.set_y_axis({
                'name': "Latency %ss"%(u"\u00b5"),
                })
            scatter_chart_bw.set_title({'name': bench})
            scatter_chart_bw.add_series({
                'name':platform,
                'categories': [coll_name, startx[0], startx[1], endx_bw[0], endx_bw[1]],
                'values':     [coll_name, start[0], start[1], end_bw[0], end_bw[1]],
                'marker': {'type': 'automatic'},
            })
            scatter_chart_bw.set_x_axis({
                'name': "Message Size (bytes)",
                'log_base': 2,
            })
            scatter_chart_bw.set_y_axis({
                'name': "Latency %ss"%(u"\u00b5"),
                'log_base': 2,
                })

            column_chart_overlap.set_title({'name': bench})
            column_chart_overlap.add_series({
                'name':platform,
                'categories': [coll_name, startx[0], startx[1], endx_overlap[0], endx_overlap[1]],
                'values':     [coll_name, start_overlap[0], start_overlap[1], end_overlap[0], end_overlap[1]],
                'marker': {'type': 'automatic'},
            })
            column_chart_overlap.set_x_axis({
                'name': "Message Size (bytes)",
            })
            column_chart_overlap.set_y_axis({
                'name': "Overlap %",
                })

            column_chart.set_size({'width': 640, 'height': 360})
            scatter_chart.set_size({'width': 640, 'height': 360})
            scatter_chart_bw.set_size({'width': 640, 'height': 360})
            column_chart_overlap.set_size({'width': 1100, 'height': 720})
        ws.insert_chart('S1',column_chart)
        ws.insert_chart('S20',scatter_chart)
        ws.insert_chart('S40',scatter_chart_bw)
        ws.insert_chart('A25',column_chart_overlap)
        return 'collective'
    def osu_iscatterv (self, ws):
        self.plot_icollective(ws, 'osu_iscatterv')
        return ' osu_iscatterv  : Parsed'
    def osu_barrier (self, ws):
        r = 0
        c = 0
        column_chart  = wb.add_chart({'type': 'column', 'subtype':'clustered'})
        for platform in benchmarks['osu_barrier']:
            print platform
            r = 0
            ws.write(r,c, "%s"%(platform))
            r = 1
            ws.write(r,c,"%s (%ss)"%("Latency", u"\u00b5"))
            r = 2
            start=(r,c)
            end=(r,c)
            for line in benchmarks_data[bench][platform][2:]:
                if line.strip()!='':
                    work=line.split()
                    ws.write_number(r,c,float(work[0]))
                r = r + 1
            startx=(0,c)
            endx=(0,c)
            c=c+1
            column_chart.add_series({
                'name':platform,
                'values':     ['osu_barrier', start[0], start[1], end[0], end[1]],
                'data_labels': {'value': True},
                'marker': {'type': 'automatic'},
            })
        column_chart.set_title({'name': bench})
        column_chart.set_x_axis({
            'name': "Barrier",
        })
        column_chart.set_y_axis({
            'name': "Latency %ss"%(u"\u00b5"),
        })
        column_chart.set_size({'width': 640, 'height': 360})
        ws.insert_chart('M1',column_chart)
        return ' osu_barrier  : Parsed'
    def osu_bibw (self, ws):
        self.plot_bandwidth(ws, 'osu_bibw')
        return ' osu_bibw  : Parsed'
    def osu_cas_latency (self, ws):
        self.plot_latency(ws, 'osu_cas_latency',8,1)
        return ' osu_cas_latency  : Parsed'
    def osu_put_bibw (self, ws):
        self.plot_bandwidth(ws, 'osu_put_bibw')
        return ' osu_put_bibw  : Parsed'
    def osu_ibcast (self, ws):
        self.plot_icollective(ws, 'osu_ibcast')
        return ' osu_ibcast  : Parsed'
    def osu_get_acc_latency (self, ws):
        self.plot_latency(ws, 'osu_get_acc_latency',0,8)
        return ' osu_get_acc_latency  : Parsed'
    def osu_scatterv (self, ws):
        self.plot_collective(ws, 'osu_scatterv')
        return ' osu_scatterv  : Parsed'
    def osu_iscatter (self, ws):
        self.plot_icollective(ws, 'osu_iscatter')
        return ' osu_iscatter  : Parsed'
    def osu_gatherv (self, ws):
        self.plot_collective(ws, 'osu_gatherv')
        return ' osu_gatherv  : Parsed'
    def osu_get_latency (self, ws):
        self.plot_latency(ws, 'osu_get_latency',0,8)
        return ' osu_get_latency  : Parsed'
    def osu_bw (self, ws):
        self.plot_bandwidth(ws, 'osu_bw')
        return ' osu_bw  : Parsed'
    def osu_allreduce (self, ws):
        self.plot_collective(ws, 'osu_allreduce')
        return ' osu_allreduce  : Parsed'
    def osu_ialltoall (self, ws):
        self.plot_icollective(ws, 'osu_ialltoall')
        return ' osu_ialltoall  : Parsed'
    def osu_ialltoallw (self, ws):
        self.plot_icollective(ws, 'osu_ialltoallw')
        return ' osu_ialltoallw  : Parsed'
    def osu_put_latency (self, ws):
        self.plot_latency(ws, 'osu_put_latency',0,8)
        return ' osu_put_latency  : Parsed'
    def osu_multi_lat (self, ws):
        self.plot_latency(ws, 'osu_multi_lat',0,8)
        return ' osu_multi_lat  : Parsed'
    def osu_iallgather (self, ws):
        self.plot_icollective(ws, 'osu_iallgather')
        return ' osu_iallgather  : Parsed'
    def osu_latency (self, ws):
        self.plot_latency(ws, 'osu_latency')
        return ' osu_latency  : Parsed'
    def osu_igather (self, ws):
        self.plot_icollective(ws, 'osu_igather')
        return ' osu_igather  : Parsed'
    def osu_iallreduce (self, ws):
        self.plot_icollective(ws, 'osu_iallreduce')
        return ' osu_iallreduce  : Parsed'
    def osu_ibarrier (self, ws):
        r = 0
        c = 0
        column_chart  = wb.add_chart({'type': 'column', 'subtype':'clustered'})
        column_chart_overlap  = wb.add_chart({'type': 'column', 'subtype':'clustered'})
        for platform in benchmarks['osu_ibarrier']:
            print platform
            r = 0
            ws.write(r,c, "%s"%(platform))
            r = 1
            ws.write(r,c,"%s (%ss)"%("Latency", u"\u00b5"))
            ws.write(r,c+1,"%s"%("Overlap %"))
            r = 2
            start=(r,c)
            end=(r,c)
            end_overlap=(r,c+1)
            start_overlap=(r,c+1)
            for line in benchmarks_data[bench][platform][3:]:
                if line.strip()!='':
                    work=line.split()
                    ws.write_number(r,c,float(work[2]))
                    ws.write_number(r,c+1,float(work[3]))
                    end=(r,c)
                    end_overlap=(r,c+1)
                r = r + 1
            c=c+2
            startx=(2,0)
            endx=(2,0)
            endx_overlap=(3,0)
            column_chart.set_title({'name': bench})
            column_chart.add_series({
                'name':platform,
                'categories': ['osu_ibarrier', startx[0], startx[1], endx[0], endx[1]],
                'values':     ['osu_ibarrier', start[0], start[1], end[0], end[1]],
                'marker': {'type': 'automatic'},
            })
            column_chart.set_x_axis({
                'name': "Message Size (bytes)",
            })
            column_chart.set_y_axis({
                'name': "Latency %ss"%(u"\u00b5"),
                })
            column_chart_overlap.set_title({'name': bench})
            column_chart_overlap.add_series({
                'name':platform,
                'categories': ['osu_ibarrier', startx[0], startx[1], endx_overlap[0], endx_overlap[1]],
                'values':     ['osu_ibarrier', start_overlap[0], start_overlap[1], end_overlap[0], end_overlap[1]],
                'marker': {'type': 'automatic'},
            })
            column_chart_overlap.set_x_axis({
                'name': "Message Size (bytes)",
            })
            column_chart_overlap.set_y_axis({
                'name': "Overlap %",
                })

            column_chart.set_size({'width': 640, 'height': 360})
            column_chart_overlap.set_size({'width': 1100, 'height': 720})
        ws.insert_chart('S1',column_chart)
        ws.insert_chart('A25',column_chart_overlap)

        return ' osu_ibarrier  : Parsed'
    def osu_scatter (self, ws):
        self.plot_collective(ws, 'osu_scatter')
        return ' osu_scatter  : Parsed'
    def osu_bcast (self, ws):
        self.plot_collective(ws, 'osu_bcast')
        return ' osu_bcast  : Parsed'
    def osu_ialltoallv (self, ws):
        self.plot_icollective(ws, 'osu_ialltoallv')
        return ' osu_ialltoallv  : Parsed'
    def osu_allgatherv (self, ws):
        self.plot_collective(ws, 'osu_allgatherv')
        return ' osu_allgatherv  : Parsed'
    def osu_ireduce (self, ws):
        self.plot_icollective(ws, 'osu_ireduce')
        return ' osu_ireduce  : No Parsed'
    def osu_allgather (self, ws):
        self.plot_collective(ws, 'osu_allgather')
        return ' osu_allgather  : Parsed'
    def osu_gather (self, ws):
        self.plot_collective(ws, 'osu_gather')
        return ' osu_gather  : Parsed'
    def osu_igatherv (self, ws):
        self.plot_icollective(ws, 'osu_igatherv')
        return ' osu_igatherv  : Parsed'
    def osu_get_bw (self, ws):
        self.plot_bandwidth(ws, 'osu_get_bw')
        return ' osu_get_bw  : Parsed'
    def osu_alltoallv (self, ws):
        self.plot_collective(ws, 'osu_alltoallv')
        return ' osu_alltoallv  : Parsed'
    def osu_acc_latency (self, ws):
        self.plot_latency(ws, 'osu_acc_latency',0,8)
        return ' osu_acc_latency  : Parsed'
    def osu_iallgatherv (self, ws):
        self.plot_icollective(ws, 'osu_iallgatherv')
        return ' osu_iallgatherv  : Parsed'
    def osu_mbw_mr (self, ws):
        r = 0
        c = 0
        max_points = 8
        ws.write(1, 0, "%s"%("Size"))
        for x in range(0, max_points):
            ws.write(2+x, 0, math.pow(2,x))
        scatter_chart = wb.add_chart({'type': 'scatter', 'subtype':'straight_with_markers'})
        column_chart  = wb.add_chart({'type': 'column', 'subtype':'clustered'})
        c=1
        for platform in benchmarks['osu_mbw_mr']:
            print platform
            r = 0
            ws.write(r,c, "%s"%(platform))
            r = 1
            ws.write(r,c,"%s"%("Message Rate (Messages/s)"))
            r = 2
            start=(r,c)
            end=(r,c)
            parse_lines=max_points
            for line in benchmarks_data[bench][platform][1:]:
                if parse_lines==0:
                    continue
                parse_lines=parse_lines-1
                if line.strip()!='':
                    work=line.split()
                    ws.write_number(r,c,float(work[2])/1000000)
                    end=(r,c)
                r = r + 1
            c=c+1
            startx=(2,0)
            endx=(1+max_points,0)
            column_chart.set_title({'name': bench})
            column_chart.add_series({
                'name':platform,
                'categories': ['osu_mbw_mr', startx[0], startx[1], endx[0], endx[1]],
                'values':     ['osu_mbw_mr', start[0], start[1], end[0], end[1]],
                'marker': {'type': 'automatic'},
            })
            column_chart.set_x_axis({
                'name': "Message Size (bytes)",
            })
            column_chart.set_y_axis({
                'name': "Message Rate(MMPS)",
                })
            scatter_chart.set_title({'name': bench})
            scatter_chart.add_series({
                'name':platform,
                'categories': ['osu_mbw_mr', startx[0], startx[1], endx[0], endx[1]],
                'values':     ['osu_mbw_mr', start[0], start[1], end[0], end[1]],
                'marker': {'type': 'automatic'},
            })
            scatter_chart.set_x_axis({
                'name': "Message Size (bytes)",
            })
            scatter_chart.set_y_axis({
                'name': "Message Rate (MMPS)",
                })
            column_chart.set_size({'width': 640, 'height': 360})
            scatter_chart.set_size({'width': 640, 'height': 360})
        ws.insert_chart('M1',column_chart)
        ws.insert_chart('M20',scatter_chart)
        return ' osu_mbw_mr  : Parsed'
    def osu_fop_latency (self, ws):
        self.plot_latency(ws, 'osu_fop_latency',8,1)
        return ' osu_fop_latency  : Parsed'
    def osu_reduce (self, ws):
        self.plot_collective(ws, 'osu_reduce')
        return ' osu_reduce  : Parsed'
    def osu_reduce_scatter (self, ws):
        self.plot_collective(ws, 'osu_reduce_scatter')
        return ' osu_reduce_scatter  : Parsed'
    def osu_latency_mt (self, ws):
        self.plot_latency(ws, 'osu_latency_mt')
        return ' osu_latency_mt  : Parsed'
    def osu_alltoall (self, ws):
        self.plot_collective(ws, 'osu_alltoall')
        return ' osu_alltoall  : Parsed'
    def osu_put_bw (self, ws):
        self.plot_bandwidth(ws, 'osu_put_bw')
        return ' osu_put_bw  : Parsed'


myparser    = Parser()
non_decimal = re.compile(r'[^\d.]+')


def skip_comments(file):
    for line in file:
        if not line.strip().startswith('#') and \
           not line.strip().startswith('-') and \
           not line.strip().startswith('a non') and \
           not line.strip().startswith('Overall') and \
           not line.strip().startswith('Primary') and \
           not line.strip().startswith('YOUR APPLICATION TERMINATED WITH THE') and \
           not line.strip().startswith('APPLICATION TERMINATED WITH THE') and \
           not line.strip().startswith('This typically refers to') and \
           not line.strip().startswith('Please see the FAQ page for debugging') and \
           not line.strip().startswith('  ') and \
           not line.strip().startswith('='):
            yield line.rstrip()


os.chdir(subdir)
os.listdir(os.curdir)

extensions = ['out' ] ;
file_names = [fn for fn in os.listdir(os.curdir) if any([fn.endswith(ext) for ext in extensions])];

for file in file_names:
    tmp=file.split('.')
    benchmarks[tmp[0]].append(tmp[1])
    f = open(file)
    for line in skip_comments(f):
        benchmarks_data[tmp[0]][tmp[1]].append(line)


for bench, platforms in benchmarks.iteritems():
    benchmarks_func[bench]=getattr(myparser,bench)
    # for platform in platforms:
    #     print bench, platform
    #     for line in benchmarks_data[bench][platform][2:]:
    #         if line.strip()!='':
    #             print line.strip()

sheet_id = 0
for bench, platforms in benchmarks.iteritems():
    ws       = wb.add_worksheet(bench)
    ws.title = bench
    print bench
    print benchmarks_func[bench](ws)
    sheet_id = sheet_id + 1


wb.close()
#print benchmarks
# OSU Latency Handler
#f = open('osu_latency.ch4.out')
#for line in skip_comments(f)[2:]:
#     line

