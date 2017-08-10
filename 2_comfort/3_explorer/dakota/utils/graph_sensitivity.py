#!/usr/bin/python
from plotly.offline import download_plotlyjs, init_notebook_mode, plot, iplot
import plotly
import plotly.plotly as py
import plotly.graph_objs as go
import numpy as np
from scipy import stats
import sys

# get the number of columns
f=open(sys.argv[1],"r")
cols=f.read().splitlines()[0].split()
f.close()

numDescriptors=int(sys.argv[2])

goodcols=[cols[c] for c in range(1,len(cols))]
inputs=[cols[c] for c in range(1,numDescriptors+1)]
outputs=[cols[c] for c in range(numDescriptors+1,len(cols))]

pts=np.loadtxt(sys.argv[1],skiprows=1,usecols=range(1,len(cols)))

# filter out errored results
try:
    ptcheck= [ list(item) for item in pts ]
except:
    print "Only one sample... cannot graph"
    exit(1)

if len(pts)>1:
    pts=pts[pts[:,numDescriptors]<1000,:]

gg=[np.array(a) for a in zip(*pts)]

colmap={}
for i,g in enumerate(gg):
    colmap[goodcols[i]]=g

fig = plotly.tools.make_subplots(rows=len(outputs), cols=len(inputs), shared_yaxes=True, shared_xaxes=True)

for i,out in enumerate(outputs):
    for j,inp in enumerate(inputs):
        
        slope, intercept, r_value, p_value, std_err = stats.linregress(colmap[inp],colmap[out])
        line = slope*colmap[inp]+intercept
    
        trace1 = go.Scatter(name=inputs[j],x = colmap[inp],y = colmap[out], mode = 'markers',marker=go.Marker(size=3,color='rgb(0,0,255)'),showlegend=False)
        trace2 = go.Scatter(name='Fit',x = colmap[inp],y = line,mode = 'lines',line = dict(color = ('rgb(255, 0, 0)')),marker=go.Marker(color='rgba(255,0,0)'),showlegend=False)
        
        fig.append_trace(trace1, i+1, j+1)
        fig.append_trace(trace2, i+1, j+1)

for lay in fig['layout']:
    if "xaxis" in lay:
        index=int(lay.replace("xaxis",""))-1
        fig['layout'][lay].update(title=inputs[index])
    if "yaxis" in lay:
        index=int(lay.replace("yaxis",""))-1
        fig['layout'][lay].update(title=outputs[index])

fig['layout'].update(margin={'l': 60,'r': 20,'b': 60,'t': 20}) #title="Sensitivity Analysis Results"
        
plot(fig, filename=sys.argv[3], auto_open=False,show_link=False)

