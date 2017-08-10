#!/usr/bin/python

from plotly.offline import download_plotlyjs, init_notebook_mode, plot, iplot
import plotly
import plotly.plotly as py
import plotly.graph_objs as go
import numpy as np
import sys

# get columns
f = open(sys.argv[1],'r')
cols=f.readlines()[0].split()
cols[0]=cols[0].replace("%eval_","")
f.close()

pts=np.loadtxt(sys.argv[1],skiprows=1) # usecols=[0,num_tasks+1,num_tasks+2,num_tasks+3,num_tasks+4,num_tasks+5]

# id,max_workstations,failed_constraints,fitness,line_balance_efficiency,min_cycle_time_proximity
content=[np.array(a) for a in zip(*pts)]

#for i in range(0,len(content)):
#    print cols[i]
#    print content[i]

id=content[0]
fitness=content[-1]

"""
# generational view
pop_size=int(sys.argv[2])
generations=[]
for g in xrange(0,len(id)/pop_size):
    generations.append(g+1)

b_ws=[]
for g in xrange(0,len(id)/pop_size):
    gen=[]
    for i in xrange(g*pop_size,g*pop_size+pop_size):
        gen.append(int(max_workstations[i]))
    b_ws.append(min(gen))
trace_ws = go.Scatter(x=generations,y=b_ws,name="Max Workstations")

b_ct=[]
for g in xrange(0,len(id)/pop_size):
    gen=[]
    for i in xrange(g*pop_size,g*pop_size+pop_size):
        gen.append(int(max_cycle_time[i]))
    b_ct.append(min(gen))
trace_ct = go.Scatter(x=generations,y=b_ct,name="Max Cycle Time")

b_fit=[]
for g in xrange(0,len(id)/pop_size):
    gen=[]
    for i in xrange(g*pop_size,g*pop_size+pop_size):
        gen.append(int(fitness[i]))
    b_fit.append(min(gen))
trace_fit = go.Scatter(x=generations,y=b_fit,name="Fitness")

b_lb=[]
for g in xrange(0,len(id)/pop_size):
    gen=[]
    for i in xrange(g*pop_size,g*pop_size+pop_size):
        gen.append(int(line_balance_efficiency[i]))
    b_lb.append(min(gen))
trace_lb = go.Scatter(x=generations,y=b_lb,name="Line Balance Efficiency")

b_mct=[]
for g in xrange(0,len(id)/pop_size):
    gen=[]
    for i in xrange(g*pop_size,g*pop_size+pop_size):
        gen.append(int(min_cycle_time_proximity[i]))
    b_mct.append(min(gen))
trace_mct = go.Scatter(x=generations,y=b_mct,name="Min Cycle Time Proximity")

data = [trace_fit,trace_ct,trace_ws,trace_lb,trace_mct]

layout = dict(title='Example',legend={"orientation": "h"})
fig = dict(data=data, layout=layout)
plot(fig, filename="index.html", auto_open=False,show_link=False)
"""

skip=1
trace_fit = go.Scatter(x=[id[i] for i in xrange(0, len(id), skip)],y=[fitness[i] for i in xrange(0, len(fitness), skip)],name='Fitness',line={'color':'rgba(50,100,200,0.65)'})
#trace_ws = go.Scatter(x=[id[i] for i in xrange(0, len(id), skip)],y=[max_workstations[i] for i in xrange(0, len(max_workstations), skip)],name='Max Workstations',visible='legendonly')
#trace_lb = go.Scatter(x=[id[i] for i in xrange(0, len(id), skip)],y=[line_balance_efficiency[i] for i in xrange(0, len(line_balance_efficiency), skip)],name='Line Balance Efficiency',visible='legendonly')
#trace_mct = go.Scatter(x=[id[i] for i in xrange(0, len(id), skip)],y=[min_cycle_time_proximity[i] for i in xrange(0, len(min_cycle_time_proximity), skip)],name='Min Cycle Time Proximity',visible='legendonly')
#trace_fc = go.Scatter(x=[id[i] for i in xrange(0, len(id), skip)],y=[failed_constraints[i] for i in xrange(0, len(failed_constraints), skip)],name='Failed Constraints',visible='legendonly')
#trace_valid = go.Scatter(x=valid_x,y=valid_y,mode='markers',marker={'size':12,'color':'rgba(50,100,200,0.65)'},name='Valid Solution')
data = [trace_fit]

layout = dict(titlefont=dict( # title="sys.argv[3]",
            size=12,
            color='#7f7f7f'
        ),margin={'l': 60,'r': 20,'b': 60,'t': 60},legend={"orientation": "h"},xaxis=dict(title='Iteration',titlefont=dict(
            size=11,
            color='#7f7f7f'
        )),yaxis=dict(title='Metric',titlefont=dict(
            size=11,
            color='#7f7f7f'
        )))
fig = dict(data=data, layout=layout)
plot(fig, filename=sys.argv[2], auto_open=False,show_link=False)
