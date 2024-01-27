# Velero

[VMware Tanzu Helm Repository - Velero](https://vmware-tanzu.github.io/helm-charts/)

[Velero - Github](https://github.com/vmware-tanzu/helm-charts)

Backups should work fine with defualt env settings. The schedule will generate a name using the schedule name and timestamp.

To create a restore you will need to obtain the backup name, update the `BACKUP_SCHEDULE_NAME` in the `management` folder and create a merge request to create the restore.
