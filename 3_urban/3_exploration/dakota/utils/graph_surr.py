from plotly.offline import download_plotlyjs, init_notebook_mode, plot, iplot
import plotly
import plotly.plotly as py
import plotly.graph_objs as go
import numpy as np
from scipy import stats
import sys

pts_area=np.loadtxt('out_surrogate_area.dat',skiprows=0,usecols=[0,1,2])
pts_volume=np.loadtxt('out_surrogate_volume.dat',skiprows=0,usecols=[0,1,2])

pts_dace=np.loadtxt('out_dace.dat',skiprows=1,usecols=[1,2,3,4])

radius,height,lateral_area=[np.array(a) for a in zip(*pts_area)]
radius,height,volume=[np.array(a) for a in zip(*pts_volume)]

radius_dace,height_dace,lateral_area_dace,volume_dace=[np.array(a) for a in zip(*pts_dace)]

inputs=['radius','height']
outputs=['lateral_area','volume']

fig = plotly.tools.make_subplots(rows=1, cols=len(outputs),shared_yaxes=True, shared_xaxes=True, 
specs=[[{'is_3d': True},{'is_3d': True}]],subplot_titles=('ClipUy_avg','ClipUx_avg'))

for i,out in enumerate(outputs):

    trace_surf = go.Mesh3d(name=outputs[i],x=radius,y=height,z=eval(out),color='00ccff',intensity=eval(out),opacity=0.5,showlegend=False,colorscale='Viridis',showscale=False)
    trace_surf_pnts = go.Scatter3d(x=radius,y=height,z=eval(out),mode='markers',marker=go.Marker(size=0.8,color='rgb(0,0,0)'),opacity=0.5)
    trace_dace = go.Scatter3d(x=radius_dace,y=height_dace,z=eval(out+"_dace"),mode='markers',marker=go.Marker(size=3,color='rgb(255,0,0)'),opacity=1)

    fig.append_trace(trace_surf, 1, i+1)
    fig.append_trace(trace_surf_pnts, 1, i+1)
    fig.append_trace(trace_dace, 1, i+1)

fig['layout'].update(showlegend=False,title="DOE Results & Response Surfaces",margin=dict(l=50, r=50, b=100, t=100, pad=4))
        
plot(fig, filename=sys.argv[1], auto_open=False,show_link=False)
