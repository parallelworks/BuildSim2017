import sys
import json
import subprocess
import os

study = sys.argv[1]
params_file = sys.argv[2]
template_file=sys.argv[3]
json_file_name=sys.argv[4]
dakota_case=sys.argv[5]
runDakota=sys.argv[6]

with open(params_file) as f:
    param_list=f.read().splitlines()

if param_list[0].find("|") != -1 :  ## convert PW website format to multiple line format
	param_list=param_list[0].split("|")

params=[]
for ii in param_list:
	ii=ii.strip()
	tmp=ii.split(";")
	#if tmp[2].find("_") !=-1 :
	#	tt=tmp[2].split("_")
	#	tmp[2]=tt[0]
	#	tmp.append(tt[1])
	#elif tmp[2].find(" ") !=-1 :
	#	tt=tmp[2].split(" ")
	#	tmp[2]=tt[0]
	#	tmp.append(tt[1])
	try:
		if tmp[2].find(":") !=-1 :
			tt=tmp[2].split(":")
			tmp[2]=tt[0]
			tmp.append(tt[1])
			tmp.append(tt[2])
		else :
			tmp.append("")
		params.append(tmp)
	except:
		pass

num_changed=0
num_unchanged=0
changed_list=[]
changed_taglist=[]
changed_min=[]
changed_max=[]
changed_step=[]
unchanged_value=[]
unchanged_list=[]
unchanged_taglist=[]
num_exp=0;
for ii in params:
	if "dakota" not in ii[1]:
		if ii[3] == "" :
			num_unchanged=num_unchanged+1
			unchanged_list.append(ii[0])
			unchanged_taglist.append(ii[1])
			unchanged_value.append(ii[2])
		else :
			num_changed=num_changed+1
			changed_list.append(ii[0])
			changed_taglist.append(ii[1])
			changed_min.append(ii[2])
			changed_max.append(ii[3])
			changed_step.append(ii[4])
	elif "dakota" in ii[1]:
		if ii[0] == "num_exp":
			num_exp=ii[2]
		elif ii[0] == "max_iter":
			max_iter=ii[2]
		elif ii[0] == "pop_size":
			pop_size=ii[2]
		elif ii[0] == "eval_con":
			eval_con=ii[2]
			
in_template=""
for ii in range(len(changed_list)):
	in_template=in_template+changed_list[ii]+";"+changed_taglist[ii]+";{"+changed_list[ii]+"}\n"

for ii in range(len(unchanged_list)):
	in_template=in_template+unchanged_list[ii]+";"+unchanged_taglist[ii]+";"+unchanged_value[ii]+"\n"

with open(template_file,"w") as t:
	t.write(in_template)

def frange(x, y, jump):
  while x < y:
    yield x
    x += jump

set_values=""
num_set_values=""
max_inputs=""
min_inputs=""
input_descriptors=""
for ii in range(len(changed_list)):
	
	cmin=float(changed_min[ii])
	cmax=float(changed_max[ii])
	cstep=float(changed_step[ii])
	
	set_values_c=[round(x,5) for x in list(frange(cmin, cmax, cstep))]

	if cmax not in set_values_c:
		set_values_c.append(cmax)
	num_set_values_c=len(set_values_c)

	set_values=set_values + " " + " ".join([str(x) for x in set_values_c])
	num_set_values=num_set_values + " " + str(num_set_values_c)
	
	# used for discrete_design_range
	max_inputs=max_inputs+" "+changed_max[ii]
	min_inputs=min_inputs+" "+changed_min[ii]
	input_descriptors=input_descriptors+" \\'"+changed_list[ii]+"\\'"

num_out=0
output_descriptors=""
output_sense=""
output_weight=""
with open(json_file_name) as json_file :
	jf=json.load(json_file)
	for ii in jf.keys() :
		if jf[ii].get('extractStats','true') != 'false':
			if  jf[ii].get('sense','null') != 'null' and "Constraint" not in jf[ii].get('type'):
				num_out=num_out+1
				output_descriptors = output_descriptors + " \\'" + ii + "\\' "
				output_sense = output_sense + " \\'" + jf[ii].get('sense','min') + "\\' "
				output_weight = output_weight + " " + jf[ii].get('weight','1') 

	# add constraints if needed for study
	con_out=0
	output_con_upper=""
	output_con_lower=""
	if ("soga" in study):
		for ii in jf.keys() :
			if jf[ii].get('extractStats','true') != 'false':
				if ( "Constraint" in jf[ii].get('type')):
					con_out=con_out+1
					output_descriptors = output_descriptors + " \\'" + ii + "\\' "
		if (con_out!=0):
			# add the upper/lower bounds
			for ii in jf.keys() :
				if jf[ii].get('extractStats','true') != 'false':
					if ( "RangeConstraint" in jf[ii].get('type')):
						output_con_upper = output_con_upper + " " + jf[ii].get('upper_bounds','') + " "
						output_con_lower = output_con_lower  + " " + jf[ii].get('lower_bounds','')  + " "

# if samples.dat exists count number of samples
num_samples=0
if os.path.exists("samples.dat"):
	num_samples = sum(1 for line in open("samples.dat"))-1

os.system("sed -i 's/@@NUMBER_OF_EXPS@@/"+num_exp+"/' "+dakota_case)
os.system("sed -i 's/@@NUMBER_OF_INPUTS@@/"+str(num_changed)+"/g' "+dakota_case)
os.system("sed -i 's/@@MAX_INPUTS@@/"+max_inputs+"/' "+dakota_case)
os.system("sed -i 's/@@MIN_INPUTS@@/"+min_inputs+"/' "+dakota_case)
os.system("sed -i 's/@@NUM_SET_VALUES@@/"+num_set_values+"/' "+dakota_case)
os.system("sed -i 's/@@SET_VALUES@@/"+set_values+"/' "+dakota_case)
os.system("sed -i \"s/@@INPUT_DESCRIPTORS@@/"+input_descriptors+"/\" "+dakota_case)
os.system("sed -i 's/@@NUMBER_OF_OUTPUTS@@/"+str(num_out)+"/' "+dakota_case)
os.system("sed -i \"s/@@OUTPUT_DESCRIPTORS@@/"+output_descriptors+"/\" "+dakota_case)
os.system("sed -i 's/@@OUTPUTS_WEIGHTS@@/"+output_weight+"/' "+dakota_case)
os.system("sed -i \"s/@@OUTPUTS_SENSES@@/"+output_sense+"/\" "+dakota_case)

os.system("sed -i 's/@@TOTAL_SAMPLES@@/"+str(num_samples)+"/' "+dakota_case)
os.system("sed -i 's/@@MAX_ITERATIONS@@/"+max_iter+"/' "+dakota_case)
os.system("sed -i 's/@@POPULATION_SIZE@@/"+pop_size+"/' "+dakota_case)
os.system("sed -i 's/@@EVALUATION_CONCURRENCY@@/"+eval_con+"/' "+dakota_case)

if con_out > 0:
	os.system("sed -i 's/@@NUMBER_OF_CONSTRAINTS@@/"+str(con_out)+"/' "+dakota_case)
	os.system("sed -i \"s/@@CONSTRAINT_UPPER_BOUNDS@@/"+output_con_upper+"/\" "+dakota_case)
	os.system("sed -i \"s/@@CONSTRAINT_LOWER_BOUNDS@@/"+output_con_lower+"/\" "+dakota_case)
else:
	os.system("sed -i '/@@NUMBER_OF_CONSTRAINTS@@/d' "+dakota_case)
	os.system("sed -i '/@@CONSTRAINT_UPPER_BOUNDS@@/d' " +dakota_case)
	os.system("sed -i '/@@CONSTRAINT_LOWER_BOUNDS@@/d' " +dakota_case)

os.system("sed -i 's/@@NUMBER_OF_INPUTS@@/"+str(num_changed)+"/' "+runDakota)
