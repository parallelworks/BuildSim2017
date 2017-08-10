# BuildSim Interior Thermal Comfort Workflow

Start a local cluster with a few workers running

```
pworks cluster 2
```

Test, run and deploy the interior thermal comfort workflow:

```
cd batch

# test the geometry and openfoam models
cd model
./test.sh

# test the sweep workflow on the local cluster
cd workflow
swift comfort.swift

# create a template XML workflow file from params.run
pworks genxml params.run test.xml

# edit the xml file appropriate for your outputs

# deploy to Parallel Works
pworks deploy <apikey> workflow radiance_batch_v1

# make any needed edits to the workflow 

# scale simulations on the cloud

# test out the design exploration methods

cd exploration

swift dakota.swift -study=doe

swift dakota.swift -study=surr

swift dakota.swift -study=soga

swift dakota.swift -study=soga_surr

```
