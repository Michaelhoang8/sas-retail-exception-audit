/* Run from the repository root: sas -sysin run.sas */
%include "src/audit.sas";
%audit(root=.);
proc export data=work.accepted outfile="accepted.csv" dbms=csv replace; run;
proc export data=work.rejected outfile="rejected.csv" dbms=csv replace; run;
proc export data=work.summary outfile="summary.csv" dbms=csv replace; run;
