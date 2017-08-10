
import sys
import paramUtils

kpiFile=sys.argv[1]
outputParamStatsFile=sys.argv[2]
metricLocation=sys.argv[3]
out=sys.argv[4]

# Read the desired output metrics
outputParamNames = paramUtils.getOutputParamsFromKPI(kpiFile)
outputParamNames = list(set(outputParamNames))
outputParamList = paramUtils.getOutputParamsStatList(outputParamStatsFile, outputParamNames,['ave', 'min', 'max'])
outParamTable = paramUtils.genOutputLookupTable(outputParamList)

outParams=[]
f = open(metricLocation,'r')
metrics = f.read().splitlines()
for metric in metrics:
    m=metric.split(",")
    for o in outParamTable:
        if o[0] == m[0]:
            outParams.append(m[o[1]+1])
f.close()

f = open(out,'w')
f.write("\n".join(outParams))
f.write("\n")
f.close()