# -*- coding: utf-8 -*-

# USAGE - salome start -t -w 1 mesh.py args:STEPFILE,ELEMENTS,OUTDIR
# EXAMPLE - salome start -t -w 1 mesh.py args:massing.step,"water/ground/building3/building2/building1",output

import sys
import salome
import os 
sys.path.append(os.getcwd())

stepFile=sys.argv[1]
elements=sys.argv[2].split("/")
resultDir=sys.argv[3]
constraint=sys.argv[4]

print "stepFile:",stepFile
print "elements:",elements
print "resultDir:",resultDir

if os.path.exists(resultDir) is False:
  os.mkdir(resultDir)

salome.salome_init()
theStudy = salome.myStudy

import GEOM
from salome.geom import geomBuilder
import math
import SALOMEDS

geompy = geomBuilder.New(theStudy)

O = geompy.MakeVertex(0, 0, 0)
OX = geompy.MakeVectorDXDYDZ(1, 0, 0)
OY = geompy.MakeVectorDXDYDZ(0, 1, 0)
OZ = geompy.MakeVectorDXDYDZ(0, 0, 1)
massing_step_1 = geompy.ImportSTEP(stepFile, False, True)

explodes = geompy.MakeBlockExplode(massing_step_1, 2, 100)

geompy.addToStudy( O, 'O' )
geompy.addToStudy( OX, 'OX' )
geompy.addToStudy( OY, 'OY' )
geompy.addToStudy( OZ, 'OZ' )
geompy.addToStudy( massing_step_1, 'massing.step_1' )

for ee,e in enumerate(explodes):
  geompy.addToStudyInFather( massing_step_1, e, elements[ee] )

# calculating building sf
FloorToFloorHeight=5
SMs=[]
for e in explodes:
  if ("building" in e.GetName()):
    print ""
    print e.GetName()
    faceList=geompy.ExtractShapes(e, geompy.ShapeType["FACE"],True)
    for f in faceList:
      l,area,v = geompy.BasicProperties( f )
      vertices = geompy.ExtractShapes(f, geompy.ShapeType["VERTEX"], True)
      coordZ=[]
      for v in vertices:
        coordZ.append(geompy.PointCoordinates(v)[2])
      if (sum(coordZ)==0):
        baseFace=f
      elif (coordZ.count(coordZ[0]) == len(coordZ)):
        height=coordZ[0]
    floors=math.floor(height/FloorToFloorHeight)
    sm=area*floors
    print "Area:",area
    print "Height:",height
    print "Floors:",floors
    print "SQM:",sm
    SMs.append(sm)

totalSM=sum(SMs)
print ""
print "Total SM:",totalSM
print ""

f = open(constraint,'w')
f.write(str(totalSM))
f.close()

import  SMESH, SALOMEDS
from salome.smesh import smeshBuilder

smesh = smeshBuilder.New(theStudy)

stls=[]
for e in explodes:
  Mesh_1 = smesh.Mesh(e)
  Regular_1D = Mesh_1.Segment()
  Number_of_Segments_1 = Regular_1D.NumberOfSegments(8)
  Quadrangle_2D = Mesh_1.Quadrangle(algo=smeshBuilder.QUADRANGLE)
  Hexa_3D = Mesh_1.Hexahedron(algo=smeshBuilder.Hexa)
  isDone = Mesh_1.Compute()
  try:
    Mesh_1.ExportSTL( resultDir+ "/" + e.GetName()+'.stl', 1 )
    stls.append(resultDir+ "/" + e.GetName()+'.stl')
  except:
    print 'ExportToSTL() failed. Invalid file name?'

filename=resultDir+'/merged.stl'
try:
    os.remove(filename)
except OSError:
    pass
f = open(filename,'a')
for s in stls:
  with open(s) as fp:
    stl = [x.strip() for x in fp.readlines()]
    name=os.path.splitext(os.path.basename(s))[0]
    print name
    stl[0] = stl[0].replace("solid","solid "+name)
    stl[-1] = stl[-1].replace("endsolid","endsolid "+name)
    f.write("\n".join(stl))
  f.write("\n")
  #os.remove(s)
f.close()

#### import the simple module from the paraview
#from pvsimple import *
#mesh_stl1 = STLReader(FileNames=[filename])
#generateSurfaceNormals1 = GenerateSurfaceNormals(Input=mesh_stl1)
#generateSurfaceNormals1.ComputeCellNormals = 1
#cellCenters1 = CellCenters(Input=generateSurfaceNormals1)
#centerFilename=filename.replace(".stl","")+'_centers.vtk'
#SaveData(centerFilename, proxy=cellCenters1, FileType='Ascii')
