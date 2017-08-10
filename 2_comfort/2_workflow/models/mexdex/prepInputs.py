
import sys
sys.path.append("mexdex")
import paramUtils

if len(sys.argv) < 3:
    print("Number of provided arguments: ", len(sys.argv) - 1)
    print("Usage: python prep_inputs.py  <sweep.run>  <outputFile>")
    sys.exit()

paramsFile = sys.argv[1]
casesListFile = sys.argv[2]

f = open(paramsFile, "r")
lines=f.read().splitlines()
if "|" in lines[0]:
    paramsdelimiter="|"
else:
    paramsdelimiter="\n"
f.close()
cases = paramUtils.readCases(paramsFile, paramsdelimiter=paramsdelimiter)[0]

print("Generated "+str(len(cases))+" Cases")

caselist = paramUtils.generate_caselist(cases, pnameValDelimiter=':')

casel = "\n".join(caselist)

f = open(casesListFile, "w")
f.write(casel)
f.close()