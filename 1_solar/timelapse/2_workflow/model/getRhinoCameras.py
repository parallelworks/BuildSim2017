# USE THIS SCRIPT TO EXPORT RHINO CAMERAS FOR RADIANCE ANALYSIS

import scriptcontext

# THIS SNIPPET RETURNS CAMERA INFO FOR ALL THE SAVED VIEWS - IF NO SAVED VIEWS RETURNS ACTIVE VIEWPORT
count = scriptcontext.doc.NamedViews.Count
views = [scriptcontext.doc.NamedViews[i] for i in range(count)]

if (len(views)>0):
	for view in views:
		viewport=view.Viewport
		location=str(round(viewport.CameraLocation.X,4))+" "+str(round(viewport.CameraLocation.Y,4))+" "+str(round(viewport.CameraLocation.Z,4))
		direction=str(round(viewport.CameraDirection.X,4))+" "+str(round(viewport.CameraDirection.Y,4))+" "+str(round(viewport.CameraDirection.Z,4))
		camup=str(round(viewport.CameraUp.X,4))+" "+str(round(viewport.CameraUp.Y,4))+" "+str(round(viewport.CameraUp.Z,4))
		print location+" "+direction+" "+camup
else:
	viewport = scriptcontext.doc.Views.ActiveView.ActiveViewport
	location=str(round(viewport.CameraLocation.X,4))+" "+str(round(viewport.CameraLocation.Y,4))+" "+str(round(viewport.CameraLocation.Z,4))
	direction=str(round(viewport.CameraDirection.X,4))+" "+str(round(viewport.CameraDirection.Y,4))+" "+str(round(viewport.CameraDirection.Z,4))
	camup=str(round(viewport.CameraUp.X,4))+" "+str(round(viewport.CameraUp.Y,4))+" "+str(round(viewport.CameraUp.Z,4))
	print location+" "+direction+" "+camup