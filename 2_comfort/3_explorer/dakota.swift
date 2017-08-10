# GENERAL DAKOTA CASE RUNNER
import "stdlib.v2";

type file;

# -- INPUT / OUTPUT DEFINITIONS

string study        = arg("study","doe");
string workflowDir  = arg("workflow","workflow");
string kpiLocation  = arg("kpi","models/kpi.json");

file params         <"params.run">;
file swiftconf      <"swift.conf">;
file outdat         <arg("dat",strcat("results/",study,".dat"))>;
file outhtml        <arg("iter",strcat("results/",study,".html"))>;

file[] workflow     <Ext;exec="dakota/utils/mapper.sh",root=workflowDir>; 
file[] dakota       <Ext;exec="dakota/utils/mapper.sh",root="dakota">; 

string jobid = getEnv("PW_WORKFLOW_SERIAL_NUM");
string path = getEnv("PWD");

# -- APP DEFINITIONS

app (file pout, file perr, file dout, file derr, file outdat, file outhtml ) runDakota (string study,string workflowDir, string kpiLocation, file params, file[] workflow, file[] dakota, file swiftconf,  file points,  file samples, string path, string jobid) {
    bash "dakota/utils/prepInputs.sh" study @params kpiLocation workflowDir @points @samples stdout=@pout stderr=@perr;
    bash "templatedir/start_docker.sh" study @outdat @outhtml path jobid stdout=@dout stderr=@derr;
}

# -- WORKFLOW COMMANDS

file pout   <"logs/prep.out">;
file perr   <"logs/prep.err">;
file dout   <"logs/dakota.out">;
file derr   <"logs/dakota.err">;

if (study == "surr" || study == "soga_surr") {
    # surr model specific inputs (points and samples)
    file points         <arg("points","points.dat")>;
    file samples        <arg("samples","results/doe.dat")>;
    (pout,perr, dout, derr, outdat, outhtml) = runDakota(study, workflowDir, kpiLocation, params, workflow, dakota, swiftconf, points, samples, path, jobid);
}
else {
    file points         <"params.run">;
    file samples        <"params.run">;
    (pout,perr, dout, derr, outdat, outhtml) = runDakota(study, workflowDir, kpiLocation, params, workflow, dakota, swiftconf, points, samples, path, jobid);
}

