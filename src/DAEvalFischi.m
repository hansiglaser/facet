%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load Pilot Data
p=path;
addpath /opt/eeglab7_2_9_20b/functions/popfunc/
addpath /opt/eeglab7_2_9_20b/functions/adminfunc/
EEG_Fischi=pop_loadset('filepath','../../data','filename','EMG_withMR.set');
EEG_NeuroPrax=pop_loadset('filepath','../../data','filename','EMG_withMR_Corrected.set');
path(p);  clear p;
% generate Trigs
Trigs=FACET.FindTriggers(EEG_Fischi.event,'IA',-1550);

% Data shows a spike before fMRI acquisition at approx. 12230 which lasts
% until 13920. Fill with interpolated data.
t = 12230:13920;
si = t-t(1);
si = si / si(end);
for i=1:EEG_Fischi.nbchan
  sb = EEG_Fischi.data(i,t(1));
  se = EEG_Fischi.data(i,t(end));
  sd = se-sb;
  EEG_Fischi.data(i,t) = sb + si.*sd;
end
clear t si sb se sd;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run Niazy without Post-Processing
p=path;
addpath /opt/eeglab7_2_9_20b/plugins/fmrib1.21/
% Note: PCA uses rand(), therefore we use the same seed for every
% invocation of any algorithm.
rand('seed',0), DA_Niazy_noPCA_noLP_noANC = fmrib_fastr(EEG_Fischi, 0,10,30,Trigs,1,0,1,153,25,0.14,[14,15,21,22],0);
%rand('seed',0), DA_Niazy_noLP_noANC       = fmrib_fastr(EEG_Fischi, 0,10,30,Trigs,1,0,1,153,25,0.03,[14,15,21,22],'auto');
%rand('seed',0), DA_Niazy_noANC            = fmrib_fastr(EEG_Fischi,70,10,30,Trigs,1,0,1,153,25,0.03,[14,15,21,22],'auto');
rand('seed',0), DA_Niazy                  = fmrib_fastr(EEG_Fischi,70,10,30,Trigs,1,1,1,153,25,0.03,[14,15,21,22],'auto');
path(p);  clear p;
eval_Niazy_noPCA_noLP_noANC = FACET.EvalPrintText(FACET.Eval(EEG_Fischi,DA_Niazy_noPCA_noLP_noANC,[1:13,16:22],27073,29000,639126,648987,0.5000,12.5000).eval()).print();
%eval_Niazy_noLP_noANC       = FACET.EvalPrintText(FACET.Eval(EEG_Fischi,DA_Niazy_noLP_noANC,      [1:13,16:22],27073,29000,639126,648987,0.5000,12.5000).eval()).print();
%eval_Niazy_noANC            = FACET.EvalPrintText(FACET.Eval(EEG_Fischi,DA_Niazy_noANC,           [1:13,16:22],27073,29000,639126,648987,0.5000,12.5000).eval()).print();
eval_Niazy                  = FACET.EvalPrintText(FACET.Eval(EEG_Fischi,DA_Niazy,                 [1:13,16:22],27073,29000,639126,648987,0.5000,12.5000).eval()).print();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run Allen
% without LP and ANC:
rand('seed',0); DA_Allen_noLP_noANC = CleanEx6(EEG_Fischi,'Allen');
eval_Allen_noLP_noANC=FACET.EvalPrintText(FACET.Eval(EEG_Fischi,DA_Allen_noLP_noANC,[1:13,16:22],27073,29000,639126,648987,0.5000,12.5000).eval()).print();
% using Upsample cut-off frequency 1.0
%rand('seed',0); DA_Allen_noLP_noANC_Up10 = Allen(EEG_Fischi,false,false,true);
%eval_Allen_noLP_noANC_Up10=FACET.EvalPrintText(FACET.Eval(EEG_Fischi,DA_Allen_noLP_noANC_Up10,[1:13,16:22],27073,29000,639126,648987,0.5000,12.5000).eval()).print();
% with LP and ANC:
rand('seed',0); DA_Allen = CleanEx6(EEG_Fischi,'Allen','LowPass','ANC');
eval_Allen=FACET.EvalPrintText(FACET.Eval(EEG_Fischi,DA_Allen,[1:13,16:22],27073,29000,639126,648987,0.5000,12.5000).eval()).print();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run EEGfMRI with incremental options without Post-Processing
% create struct for Options, EEG and Eval
DADataInc = struct('Options',[],'EEG',[],'Eval',[]);
DADataInc(1).Options = {'Upsample1'};
DADataInc(2).Options = {'PreFilter','Upsample1'};
DADataInc(3).Options = {'PreFilter'};
DADataInc(4).Options = {'PreFilter','AlignSubSample'};
DADataInc(5).Options = {'PreFilter','AlignSubSample','RemoveVolumeArt'};
DADataInc(6).Options = {'PreFilter','AlignSubSample','RemoveVolumeArt','AvgArtWghtFARM'};
% InterpolateVolumeGaps doesn't make a difference
% further options for post-processing: 'PCA','LowPass','ANC'
% run
for i=1:length(DADataInc)
  fprintf('#### Run %d of %d: Options: %s\n',i,length(DADataInc),FACET.StrJoinCell(', ',DADataInc(i).Options));
  rand('seed',0);
  DADataInc(i).EEG  = CleanEx6(EEG_Fischi,DADataInc(i).Options{:});
  DADataInc(i).Eval = FACET.Eval(EEG_Fischi,DADataInc(i).EEG,[1:13,16:22],27073,29000,639126,648987,0.5000,12.5000).eval();
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run EEGfMRI with incremental options for Post-Processing
% create struct for Options, EEG and Eval
DADataIncPost = struct('Options',[],'EEG',[],'Eval',[]);
DADataIncPost(1).Options = {'PreFilter','AlignSubSample','RemoveVolumeArt','AvgArtWghtFARM'};
DADataIncPost(2).Options = {'PreFilter','AlignSubSample','RemoveVolumeArt','AvgArtWghtFARM','PCA'};
DADataIncPost(3).Options = {'PreFilter','AlignSubSample','RemoveVolumeArt','AvgArtWghtFARM','PCA','LowPass'};
DADataIncPost(4).Options = {'PreFilter','AlignSubSample','RemoveVolumeArt','AvgArtWghtFARM','PCA','LowPass','ANC'};
% run
for i=1:length(DADataIncPost)
  fprintf('#### Run %d of %d: Options: %s\n',i,length(DADataIncPost),FACET.StrJoinCell(', ',DADataIncPost(i).Options));
  rand('seed',0);
  DADataIncPost(i).EEG  = CleanEx6(EEG_Fischi,DADataIncPost(i).Options{:});
  DADataIncPost(i).Eval = FACET.Eval(EEG_Fischi,DADataIncPost(i).EEG,[1:13,16:22],27073,29000,639126,648987,0.5000,12.5000).eval();
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Evaluate dataset corrected by NeuroPrax
% put AcqPostStart a bit later because of 2s oscillations
eval_NeuroPrax = FACET.EvalPrintText(FACET.Eval(EEG_Fischi,EEG_NeuroPrax,[1:13,16:22],27073,33500,639126,648987,0.5000,12.5000).eval()).print();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Create LaTeX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compare Allen, Niazy and FACET without Post-Processing
% Create LaTeX include file with tables and diagrams
DAEPLNoPost=FACET.EvalPrintLaTeX();
DAEPLNoPost.AddResult(FACET.EvalResultContainer(eval_Allen_noLP_noANC,      'Allen'));
DAEPLNoPost.AddResult(FACET.EvalResultContainer(eval_Niazy_noPCA_noLP_noANC,'Niazy'));
DAEPLNoPost.AddResult(FACET.EvalResultContainer(DADataInc(1).Eval,          'EEGfMRI'));
DAEPLNoPost.CmdPrefix='FischiNoPost';
DAEPLNoPost.GraphErrorBars=false;
% DAEPLNoPost.print();
fid=fopen('/home/hansi/Uni/Diplomarbeit-Psychologie-MRI/thesis/images/eval-Fischi-NoPost.inc.tex','w');
DAEPLNoPost.print(fid);
fclose(fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compare EEGfMRI with incremental options without Post-Processing
% create labels
for i=1:length(DADataInc)
  DADataInc(i).Short = ['(',char(i+'a'-1),')'];
  DADataInc(i).Label = ['+' DADataInc(i).Options{end}];
end
DADataInc(1).Label = 'raw';
DADataInc(2).Label = '+PreFilter';
DADataInc(3).Label = '+Upsample0.5';
% create LaTeX table and figures
DAEPLInc=FACET.EvalPrintLaTeX();
for i=1:length(DADataInc)
  DAEPLInc.AddResult(FACET.EvalResultContainer(DADataInc(i).Eval,DADataInc(i).Short));
end
DAEPLInc.CmdPrefix='FischiIncremental';
DAEPLInc.GraphErrorBars=false;
% DAEPLInc.print();
fid=fopen('/home/hansi/Uni/Diplomarbeit-Psychologie-MRI/thesis/images/eval-Fischi-Incremental.inc.tex','w');
DAEPLInc.print(fid);
fprintf(fid,'\n');
fprintf(fid,'\\newcommand{\\%sLabels}[1]{%%\n',DAEPLInc.CmdPrefix);
for i=1:length(DADataInc)-1
  fprintf(fid,'%s~%s#1%%\n',DADataInc(i).Short,DADataInc(i).Label);
end
fprintf(fid,'%s~%s%%\n',DADataInc(end).Short,DADataInc(end).Label);
fprintf(fid,'}\n');
fclose(fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compare EEGfMRI with incremental options for Post-Processing
% create labels
for i=1:length(DADataIncPost)
  DADataIncPost(i).Short = ['(',char(i+'a'-1),')'];
  DADataIncPost(i).Label = ['+' DADataIncPost(i).Options{end}];
end
DADataIncPost(1).Label = 'previous';
% create LaTeX table and figures
DAEPLIncPost=FACET.EvalPrintLaTeX();
for i=1:length(DADataIncPost)
  DAEPLIncPost.AddResult(FACET.EvalResultContainer(DADataIncPost(i).Eval,DADataIncPost(i).Short));
end
DAEPLIncPost.CmdPrefix='FischiIncrementalPost';
DAEPLIncPost.GraphErrorBars=false;
% DAEPLIncPost.print();
fid=fopen('/home/hansi/Uni/Diplomarbeit-Psychologie-MRI/thesis/images/eval-Fischi-IncrementalPost.inc.tex','w');
DAEPLIncPost.print(fid);
fprintf(fid,'\n');
fprintf(fid,'\\newcommand{\\%sLabels}[1]{%%\n',DAEPLIncPost.CmdPrefix);
for i=1:length(DADataIncPost)-1
  fprintf(fid,'%s~%s#1%%\n',DADataIncPost(i).Short,DADataIncPost(i).Label);
end
fprintf(fid,'%s~%s%%\n',DADataIncPost(end).Short,DADataIncPost(end).Label);
fprintf(fid,'}\n');
fclose(fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compare Allen, Niazy and FACET with Post-Processing
% Create LaTeX include file with tables and diagrams
DAEPLPost=FACET.EvalPrintLaTeX();
DAEPLPost.AddResult(FACET.EvalResultContainer(eval_Allen,             'Allen'));
DAEPLPost.AddResult(FACET.EvalResultContainer(eval_Niazy,             'Niazy'));
DAEPLPost.AddResult(FACET.EvalResultContainer(DADataIncPost(end).Eval,'EEGfMRI'));
DAEPLPost.AddResult(FACET.EvalResultContainer(eval_NeuroPrax,         'NeuroPrax'));
DAEPLPost.CmdPrefix='FischiPost';
DAEPLPost.GraphErrorBars=false;
% DAEPLPost.print();
fid=fopen('/home/hansi/Uni/Diplomarbeit-Psychologie-MRI/thesis/images/eval-Fischi-Post.inc.tex','w');
DAEPLPost.print(fid);
fclose(fid);
