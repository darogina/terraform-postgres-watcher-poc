PostgreSQL Git Watcher & Builder
====================
This project stands up a PostgreSQL build system leveraging Terraform, PostgreSQL PGDG RPM Spec, and GitHub PostgreSQL Mirror.  Terraform is used to create two RHEL 7 environments, one which listens for all new commits to the Github PostgreSQL mirror and another to build the corresponding commits.  Both environments can be configured to scale to accomidate a large backlog of builds.  Amazon SQS is used to facilitate communication between the two enviornments.  Upon successful build and execution of the full Postgres regression suite, RPMs will be attempted to be built for the new source.

### Project Structure ###

```
.
├── providers  
│   └── aws  
│       └── <region>  
│           └── <environment>  
│               ├── *.tf 
│               ├── terraform.tfvars 
│               ├── scripts/ 
└── setup  
    └── ssh_key_gen.sh  
```

### Setup ###

Before you begin, SSH keys must be generated.  Run the following command replacing the two args with the appropriate values.

```
$ sh ./setup/ssh_key_gen.sh <PROJECT> <ENVIRONMENT>
```

<PROJECT> and <ENVIRONMENT> should match the values supplied in ./providers/aws/<region>/<environment>/terraform.tfvars