# Call_AtoI_Editing
Adapted from Liu et al. 2017, PNAS

Submit the complete workflow with:

```bash
bash submitMapAndEdit.sh RNA_accessions.txt
```

The submission script maps the three genomic controls in parallel, merges and
splits them in a dependent job, then releases all RNA mapping/editing jobs in
parallel after the merge succeeds. The control accessions are defined at the
top of `submitMapAndEdit.sh`.
