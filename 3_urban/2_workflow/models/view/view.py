# -*- coding: utf-8 -*-

# USAGE - pvpython view.py DATADIR ORIGINS TARGETS
# EXAMPLE - pvpython view.py output "building1/building2/building3" "water"

from __future__ import division

import vtk,sys
from vtk.util import numpy_support
import numpy as np
import random
import subprocess

class ViewCalculator:

    def __init__(self,dataDir):
        
        proc = subprocess.Popen("cat output/merged.stl | grep ^solid | sed 's|solid ||g' | tr '\n' ',' | sed 's/.$//'", shell=True, stdout=subprocess.PIPE)
        self.elements = proc.stdout.read().split(",")
        print "elements:",self.elements
        print ""

        self.dataDir = dataDir
        self.stlFileName = dataDir+'/merged.stl'
        self.viewConeAngle = 60

    def run(self,origins,targets):

        reader = vtk.vtkSTLReader()
        reader.SetFileName(self.stlFileName)
        reader.ScalarTagsOn()
        reader.Update()
        datas = reader.GetOutput()
        
        nc = datas.GetCellData().GetArray('STLSolidLabeling')
        type = numpy_support.vtk_to_numpy(nc)
        
        # make the origin and target elements
        targetsElements=[]
        originsElements=[]
        for ie,e in enumerate(self.elements):
            if e in targets:
                targetsElements.extend(np.where( type == ie )[0].tolist())
            if e in origins:
                originsElements.extend(np.where( type == ie )[0].tolist())

        def selectElements(name,selectArray,exportVTK):

            ids = vtk.vtkIdTypeArray()
            ids.SetNumberOfComponents(1)
         
            for i in selectArray:
                ids.InsertNextValue(i)
        
            selectionNode = vtk.vtkSelectionNode()
            selectionNode.SetFieldType(vtk.vtkSelectionNode.CELL)
            selectionNode.SetContentType(vtk.vtkSelectionNode.INDICES)
            selectionNode.SetSelectionList(ids)
         
            selection = vtk.vtkSelection()
            selection.AddNode(selectionNode)
         
            extractSelection = vtk.vtkExtractSelection()
            extractSelection.SetInputConnection(0, reader.GetOutputPort())
            extractSelection.SetInputData(1, selection)
            extractSelection.Update()
         
            selected = vtk.vtkUnstructuredGrid()
            selected.ShallowCopy(extractSelection.GetOutput())
            
            meshToSurfaceFilter = vtk.vtkGeometryFilter()
            meshToSurfaceFilter.SetInputData(selected)
            meshToSurfaceFilter.Update()
        
            #surface = meshToSurfaceFilter.GetOutput()

            cleaner = vtk.vtkCleanPolyData()
            cleaner.SetInputData(meshToSurfaceFilter.GetOutput())
            cleaner.Update()
            surface = cleaner.GetOutput()
            
            normals = vtk.vtkPolyDataNormals()
            normals.SetInputData(surface)
            normals.ComputeCellNormalsOn()
            normals.ComputePointNormalsOn()
            normals.ConsistencyOn()
            normals.AutoOrientNormalsOn()
            normals.SplittingOn()
            normals.Update()
            surface = normals.GetOutput()
            
            norms = numpy_support.vtk_to_numpy(surface.GetPointData().GetArray('Normals'))

            noPoints = surface.GetPoints().GetNumberOfPoints()
            points = np.zeros((noPoints, 3))
            ptCount=0
            for i in points:
                point = surface.GetPoints().GetPoint(ptCount)
                i[0]=point[0]
                i[1]=point[1]
                i[2]=point[2]
                ptCount+=1
                
            if exportVTK == True:
                writer = vtk.vtkDataSetWriter()
                writer.SetFileName('output/'+name+'.vtk')
                writer.SetInputData(surface)
                writer.Write()

            return [points,norms,surface]
        
        [targetPoints,targetNormals,targetElements] = selectElements('targets',targetsElements,False)
        [originPoints,originNormals,originElements] = selectElements('origins',originsElements,False)
        
        ### VIEW ANALYSIS
        
        import math

        obbBuildings = vtk.vtkOBBTree()
        obbBuildings.SetDataSet(originElements)
        obbBuildings.BuildLocator()
        
        def isHit(obbTree, pSource, pTarget):
            code = obbTree.IntersectWithLine(pSource, pTarget, None, None)
            if code==0:
                return False
            return True
        
        def GetIntersect(obbTree, pSource, pTarget):
                
            # Create an empty 'vtkPoints' object to store the intersection point coordinates
            points = vtk.vtkPoints()
            # Create an empty 'vtkIdList' object to store the ids of the cells that intersect
            # with the cast rays
            cellIds = vtk.vtkIdList()
                
            # Perform intersection
            code = obbTree.IntersectWithLine(pSource, pTarget, points, cellIds)
                
            # Get point-data 
            pointData = points.GetData()
            # Get number of intersection points found
            noPoints = pointData.GetNumberOfTuples()
            # Get number of intersected cell ids
            noIds = cellIds.GetNumberOfIds()
                
            assert (noPoints == noIds)
                
            # Loop through the found points and cells and store
            # them in lists
            pointsInter = []
            cellIdsInter = []
            for idx in range(noPoints):
                pointsInter.append(pointData.GetTuple3(idx))
                cellIdsInter.append(cellIds.GetId(idx))
            
            return pointsInter, cellIdsInter
        
        # check if originPoint z>0 and z<30
        originPts=[]
        originNos=[]
        for op in xrange(0,len(originPoints)):
            originPoint=originPoints[op]
            normalPoint=originNormals[op]
            # offset to avoid collisions
            offsetDistance=0.1
            # find a way to ignore top and bottom surface
            originPts.append(originPoint+(offsetDistance*normalPoint))
            originNos.append(normalPoint*offsetDistance)
        
        targetPts=[]
        targetNos=[]
        for tp in xrange(0,len(targetPoints)):
            targetPoint=targetPoints[tp]
            normalPoint=targetNormals[tp]
            # offset to avoid collisions
            offsetDistance=0.1
            if (targetPoint[2]>=0): # only to top of target objects
                targetPts.append(targetPoint+(offsetDistance*normalPoint))
                targetNos.append(normalPoint*offsetDistance)
        
        print "OriginsPoints:",len(originPts)
        print "TargetPoints:",len(targetPts)
        print ""
        
        """
        pointCollide = vtk.vtkPoints()
        vertexCollide = vtk.vtkCellArray()
        ptcount=0
        """

        # HELPER FUNCTIONS FOR VIEW ANGLE
        
        def vectorDir(this,v):
            this[0] -= v[0];
            this[1] -= v[1];
            this[2] -= v[2];
            return this
		
        def length(this):
            return math.sqrt( this[0] * this[0] + this[1] * this[1] + this[2] * this[2] )
		
        def lengthSq(this):
		    return this[0] * this[0] + this[1] * this[1] + this[2] * this[2]
		
        def normalize(this):
            this[0] *= 1/length(this)
            this[1] *= 1/length(this)
            this[2] *= 1/length(this)
            return this

        def dot(this,v):
            return this[0] * v[0] + this[1] * v[1] + this[2] * v[2]
        
        def clamp(value,minv,maxv):
            return max( minv, min( maxv, value ) )
        
        def angleTo(this,v):
            theta = dot( this, v ) / ( math.sqrt( lengthSq(this) * lengthSq(v) ) )
            return math.acos( clamp( theta, - 1, 1 ) );
            
        iterCount=0
        originViews=[]
        for op in xrange(0,len(originPts)):
            
            originPoint=originPts[op]
            originNo=originNos[op]

            iterCount+=1
            print 'Progress {:2.1%} - {}/{}\r'.format(iterCount/len(originPts),iterCount,len(originPts)),
        
            # find a way to limit the top values
            if (originPoint[2]<=0):
                originViews.append(0)
                continue

            targetViews=[]
            for tp in xrange(0,len(targetPts)):
                targetPoint=targetPts[tp]
                targetNo=targetNos[tp]

                # get the angle between the direction and the normal
                dir = normalize(vectorDir(list(targetPoint),list(originPoint)))
                viewAngle = math.degrees(angleTo(dir, originNo ))
                #print viewAngle

                if (viewAngle <= self.viewConeAngle):
                    if (isHit(obbBuildings, originPoint, targetPoint)==False):
                            #print 'los'
                            targetViews.append(1)
                    else:
                            #print 'hit'
                            targetViews.append(0)
                           
                            """
                            pointsInter, cellIdsInter = GetIntersect(obbBuildings, originPoint, targetPoint)
                            #print pointsInter
                            #for ii in pointsInter:
                            pointCollide.InsertPoint(ptcount, pointsInter[0])
                            vertexCollide.InsertNextCell(1)
                            vertexCollide.InsertCellPoint(ptcount)
                            ptcount+=1
                            """
            #if (op == 10):
            #    sys.exit(1)
            originViews.append(sum(targetViews))
        
        """
        pointCollideData = vtk.vtkPolyData()
        pointCollideData.SetPoints(pointCollide)
        pointCollideData.SetVerts(vertexCollide)
        writer = vtk.vtkDataSetWriter()
        writer.SetFileName('collidePoint.vtk')
        writer.SetInputData(pointCollideData)
        writer.Write()
        """
        
        minOriginViews=min(originViews)
        maxOriginViews=max(originViews)
        
        print "\n"
        print "MinLOSViewCount:",minOriginViews
        print "MaxLOSViewCount:",maxOriginViews
        
        ocount=0
        dd = np.zeros((len(originsElements), 1))
        for ii,i in enumerate(dd):
            try:
                i[0]=originViews[ii] #/maxOriginViews
            except:
                i[0]=0
        
        b = numpy_support.numpy_to_vtk(dd, deep=True)
        b.SetName('ViewScore')
        originElements.GetPointData().AddArray(b)
        
        dd = np.zeros((len(targetsElements), 1))
        for ii,i in enumerate(dd):
            i[0]=0
        
        b = numpy_support.numpy_to_vtk(dd, deep=True)
        b.SetName('ViewScore')
        targetElements.GetPointData().AddArray(b)
        
        appendFilter = vtk.vtkAppendPolyData()
        appendFilter.AddInputData(originElements)
        #appendFilter.AddInputData(targetElements)

        appendFilter.Update()
 
        cleanFilter = vtk.vtkCleanPolyData()
        cleanFilter.SetInputConnection(appendFilter.GetOutputPort())
        cleanFilter.Update()
        
        exportGeometry = cleanFilter.GetOutput()
        
        writer = vtk.vtkDataSetWriter()
        writer.SetFileName(self.dataDir+'/viewscore.vtk')
        writer.SetInputData(exportGeometry)
        writer.Write()

        meanScore=round(float(sum(originViews))/(len(originPts)*len(targetPts))*100,2)
        print ""
        print "MeanViewScore:",meanScore


runHere=sys.argv[0] == 'view.py'
if (runHere):
    
    print ""
    print "Running View Calculator..."
    print ""

    dataDir = sys.argv[1]
    origins = sys.argv[2].split("/")
    targets = sys.argv[3].split("/")

    print "dataDir:",dataDir
    print "origins:",origins
    print "targets:",targets

    ViewCalc = ViewCalculator(dataDir)
    
    ViewCalc.run(origins,targets)
