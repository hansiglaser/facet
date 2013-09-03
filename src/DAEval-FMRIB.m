%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load FMRIB Data
p=path;
addpath /opt/eeglab7_2_9_20b/functions/popfunc/
addpath /opt/eeglab7_2_9_20b/functions/adminfunc/
EEG_FMRIB=pop_loadset('filepath','../../doc/eeglab/fmrib','filename','FMRIB_Data.set');
path(p);  clear p;
% generate Trigs
Trigs=FACET.FindTriggers(EEG_FMRIB.event);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run Niazy without Post-Processing
p=path;
addpath /opt/eeglab7_2_9_20b/plugins/fmrib1.21/
rand('seed',0), DA_Niazy_noPCA_noLP_noANC = fmrib_fastr(EEG_FMRIB, 0,10,30,Trigs,1,0,1,40,21,0.03,[31 32],0);
%rand('seed',0), DA_Niazy_noLP_noANC       = fmrib_fastr(EEG_FMRIB, 0,10,30,Trigs,1,0,1,40,21,0.03,[31 32],'auto');
%rand('seed',0), DA_Niazy_noANC            = fmrib_fastr(EEG_FMRIB,70,10,30,Trigs,1,0,1,40,21,0.03,[31 32],'auto');
rand('seed',0), DA_Niazy                  = fmrib_fastr(EEG_FMRIB,70,10,30,Trigs,1,1,1,40,21,0.03,[31 32],'auto');
path(p);  clear p;
eval_Niazy_noPCA_noLP_noANC = FACET.EvalPrintText(FACET.Eval(EEG_FMRIB,DA_Niazy_noPCA_noLP_noANC,[1:30],21).eval()).print();
%eval_Niazy_noLP_noANC       = FACET.EvalPrintText(FACET.Eval(EEG_FMRIB,DA_Niazy_noLP_noANC,      [1:30],21).eval()).print();
%eval_Niazy_noANC            = FACET.EvalPrintText(FACET.Eval(EEG_FMRIB,DA_Niazy_noANC,           [1:30],21).eval()).print();
eval_Niazy                  = FACET.EvalPrintText(FACET.Eval(EEG_FMRIB,DA_Niazy,                 [1:30],21).eval()).print();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run Allen
% without LP and ANC:
rand('seed',0); DA_CleanEx4_noLP_noANC = CleanEx4(EEG_FMRIB,false,false);
eval_CleanEx4_noLP_noANC=FACET.EvalPrintText(FACET.Eval(EEG_FMRIB,DA_CleanEx4_noLP_noANC,[1:30],21).eval()).print();
% using Upsample cut-off frequency 1.0
%rand('seed',0); DA_CleanEx4_noLP_noANC_Up10 = CleanEx4(EEG_FMRIB,false,false,true);
%eval_CleanEx4_noLP_noANC_Up10=FACET.EvalPrintText(FACET.Eval(EEG_FMRIB,DA_CleanEx4_noLP_noANC_Up10,[1:30],21).eval()).print();
% with LP and ANC:
rand('seed',0); DA_CleanEx4 = CleanEx4(EEG_FMRIB);
eval_CleanEx4=FACET.EvalPrintText(FACET.Eval(EEG_FMRIB,DA_CleanEx4,[1:30],21).eval()).print();

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
DADataInc(7).Options = {'PreFilter','AlignSubSample','RemoveVolumeArt','AvgArtWghtFARM','InterpolateVolGaps'};
% further options for post-processing: 'PCA','LowPass','ANC'
% run
for i=1:length(DADataInc)
  fprintf('#### Run %d of %d: Options: %s\n',i,length(DADataInc),FACET.StrJoinCell(', ',DADataInc(i).Options));
  rand('seed',0);
  DADataInc(i).EEG  = CleanEx5(EEG_FMRIB,DADataInc(i).Options{:});
  DADataInc(i).Eval = FACET.Eval(EEG_FMRIB,DADataInc(i).EEG,[1:30],21).eval();
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run EEGfMRI with incremental options for Post-Processing
% create struct for Options, EEG and Eval
DADataIncPost = struct('Options',[],'EEG',[],'Eval',[]);
DADataIncPost(1).Options = {'PreFilter','AlignSubSample','RemoveVolumeArt','AvgArtWghtFARM','InterpolateVolGaps'};
DADataIncPost(2).Options = {'PreFilter','AlignSubSample','RemoveVolumeArt','AvgArtWghtFARM','InterpolateVolGaps','PCA'};
DADataIncPost(3).Options = {'PreFilter','AlignSubSample','RemoveVolumeArt','AvgArtWghtFARM','InterpolateVolGaps','PCA','LowPass'};
DADataIncPost(4).Options = {'PreFilter','AlignSubSample','RemoveVolumeArt','AvgArtWghtFARM','InterpolateVolGaps','PCA','LowPass','ANC'};
% run
for i=1:length(DADataIncPost)
  fprintf('#### Run %d of %d: Options: %s\n',i,length(DADataIncPost),FACET.StrJoinCell(', ',DADataIncPost(i).Options));
  rand('seed',0);
  DADataIncPost(i).EEG  = CleanEx5(EEG_FMRIB,DADataIncPost(i).Options{:});
  DADataIncPost(i).Eval = FACET.Eval(EEG_FMRIB,DADataIncPost(i).EEG,[1:30],21).eval();
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run EEGfMRI all options plus FilterNonArtifact
DADataFNA = CleanEx5(EEG_FMRIB,'PreFilter','AlignSubSample','RemoveVolumeArt','AvgArtWghtFARM','InterpolateVolGaps','PCA','LowPass','ANC','FilterNonArtifact');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Create LaTeX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compare Allen, Niazy and EEGfMRI without Post-Processing
% Create LaTeX include file with tables and diagrams
DAEPLNoPost=FACET.EvalPrintLaTeX();
DAEPLNoPost.AddResult(FACET.EvalResultContainer(eval_CleanEx4_noLP_noANC,   'Allen'));
DAEPLNoPost.AddResult(FACET.EvalResultContainer(eval_Niazy_noPCA_noLP_noANC,'Niazy'));
DAEPLNoPost.AddResult(FACET.EvalResultContainer(DADataInc(1).Eval,          'EEGfMRI'));
DAEPLNoPost.CmdPrefix='FMRIBNoPost';
DAEPLNoPost.GraphErrorBars=false;
% DAEPLNoPost.print();
fid=fopen('/home/hansi/Uni/Diplomarbeit-Psychologie-MRI/thesis/images/eval-FMRIB-NoPost.inc.tex','w');
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
DAEPLInc.CmdPrefix='FMRIBIncremental';
DAEPLInc.GraphErrorBars=false;
% DAEPLInc.print();
fid=fopen('/home/hansi/Uni/Diplomarbeit-Psychologie-MRI/thesis/images/eval-FMRIB-Incremental.inc.tex','w');
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
DAEPLIncPost.CmdPrefix='FMRIBIncrementalPost';
DAEPLIncPost.GraphErrorBars=false;
% DAEPLIncPost.print();
fid=fopen('/home/hansi/Uni/Diplomarbeit-Psychologie-MRI/thesis/images/eval-FMRIB-IncrementalPost.inc.tex','w');
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
%%% Compare Allen, Niazy and EEGfMRI with Post-Processing
% Create LaTeX include file with tables and diagrams
DAEPLPost=FACET.EvalPrintLaTeX();
DAEPLPost.AddResult(FACET.EvalResultContainer(eval_CleanEx4,          'Allen'));
DAEPLPost.AddResult(FACET.EvalResultContainer(eval_Niazy,             'Niazy'));
DAEPLPost.AddResult(FACET.EvalResultContainer(DADataIncPost(end).Eval,'EEGfMRI'));
DAEPLPost.CmdPrefix='FMRIBPost';
DAEPLPost.GraphErrorBars=false;
% DAEPLPost.print();
fid=fopen('/home/hansi/Uni/Diplomarbeit-Psychologie-MRI/thesis/images/eval-FMRIB-Post.inc.tex','w');
DAEPLPost.print(fid);
fclose(fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Spectrograms with and without FilterNonArtifact

% see /home/hansi/Uni/Diplomarbeit-Psychologie-MRI/work/measures/fft_vandermeer.m
p=path;
path(path,'../measures/');
% create spectrogram without FilterNonArtifact
[p_u,p_c,f_u,t_u]=fft_vandermeer(EEG_FMRIB.data(1,:),DADataIncPost(4).EEG.data(1,:),EEG_FMRIB.srate);
% make a nice image
img_c = log(abs(p_c));
img_u = log(abs(p_u));
min_u = min(min(img_u)); max_u = max(max(img_u));   % don't use img_u(:) to avoid a large anonymous variable
img_c = (img_c - min_u) / (abs(max_u-min_u)/1000);  % scale to 0..1000
% set everything <0 to 0
img_c(img_c<0)=0;
img_c=round(img_c);
img_c_rgb = ind2rgb(img_c(301:-1:1,:),jet(1001));   % jet colormap
imwrite(img_c_rgb,'../../thesis/images/spectrogram-Post4.png');
size(img_c)
% 301 frequency-points x 323 time-points
[min(t_u),max(t_u),mean(diff(t_u))]
% time: 0.5 to 161.5 in steps of 0.5s
[min(f_u),max(f_u),mean(diff(f_u))]
% frequency: 0 to 300Hz in 1Hz steps 
% create spectrogram with FilterNonArtifact
[p_u,p_c,f_u,t_u]=fft_vandermeer(EEG_FMRIB.data(1,:),DADataFNA.data(1,:),EEG_FMRIB.srate);
% make a nice image
img_c = log(abs(p_c));
img_u = log(abs(p_u));
min_u = min(min(img_u)); max_u = max(max(img_u));   % don't use img_u(:) to avoid a large anonymous variable
img_c = (img_c - min_u) / (abs(max_u-min_u)/1000);  % scale to 0..1000
% set everything <0 to 0
img_c(img_c<0)=0;
img_c=round(img_c);
img_c_rgb = ind2rgb(img_c(301:-1:1,:),jet(1001));   % jet colormap
imwrite(img_c_rgb,'../../thesis/images/spectrogram-Post4FNA.png');

path(p); clear p;
clear p_u p_c f_u t_u img_c img_u min_u max_u img_c_rgb;
