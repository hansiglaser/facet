%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EVALPRINTTEXT  Pretty-print an EvalResult object for LaTeX
%
%  Copyright (c) 2010-2012 Johann Glaser <Johann.Glaser@gmx.at>
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, 
% MA  02110-1301, USA.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% How to test:
% epl=FACET.EvalPrintLaTeX();
% epl.AddResult(FACET.EvalResultContainer(measures_fischi_r150,'r150'));
% epl.AddResult(FACET.EvalResultContainer(measures_fischi_r167,'r167'));
% epl.AddResult(FACET.EvalResultContainer(measures_fischi_r167_1Hz,'r167a'));
% epl.AddResult(FACET.EvalResultContainer(measures_fischi_r167_1Hz_padded1s,'r167b'));
% epl.AddResult(FACET.EvalResultContainer(measures_fischi_r168,'r168'));
% epl.AddResult(FACET.EvalResultContainer(measures_fischi_r169,'r169'));
% epl.CmdPrefix='Fischi';
% epl.print();
% fid=fopen('/tmp/x.inc.tex','w'); epl.print(fid); fclose(fid);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Evaluate data
% measures_CleanEx4 = FACET.EvalPrintText(FACET.Eval(EEG_FMRIB,HBM_CleanEx4,[1:30],21).eval()).print();
% measures_Niazy    = FACET.EvalPrintText(FACET.Eval(EEG_FMRIB,HBM_Niazy,   [1:30],21).eval()).print();
% measures_CleanEx1 = FACET.EvalPrintText(FACET.Eval(EEG_FMRIB,HBM_CleanEx1,[1:30],21).eval()).print();
% % Create LaTeX include file with tables and diagrams
% epl=FACET.EvalPrintLaTeX();
% epl.AddResult(FACET.EvalResultContainer(measures_CleanEx4,'Allen'));
% epl.AddResult(FACET.EvalResultContainer(measures_Niazy,   'Niazy'));
% epl.AddResult(FACET.EvalResultContainer(measures_CleanEx1,'FACET'));
% epl.CmdPrefix='HBM';
% epl.print();
% fid=fopen('/home/hansi/Uni/Diplomarbeit-Psychologie-MRI/abstract/eval.inc.tex','w'); epl.print(fid); fclose(fid);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef EvalPrintLaTeX < FACET.EvalPrint

  properties(Access=public)
    % Prefix for the LaTeX commands, within which the images and tables
    % are printed.
    CmdPrefix;
  end

  properties(SetAccess=public,GetAccess=public)
    % Note: some of these values are overridden in print()!
    GraphHeight     = '60mm';
    GraphXScale     = '15mm';
    GraphBarWidth   = '8mm';
    GraphLineStyles = {'black'};
    %GraphFillStyles = {'green!50!white','cyan!50!white','blue!50!white','violet!50!white','red!50!white','orange!50!white','yellow!50!white',};
    GraphFillStyles = {'green!50!white','blue!50!white','red!50!white','orange!50!white','yellow!50!white','cyan!50!white','violet!50!white',};
    GraphErrorBars  = true;
  end

  methods(Access=public)

    function obj=EvalPrintLaTeX(EvalResultOrContainer)
      if nargin == 0
        EvalResultOrContainer = [];
        % Matlab doesn't like it if the argument is skipped
      end
      % call constructor of super-class
      obj = obj@FACET.EvalPrint(EvalResultOrContainer);
    end

    % Pretty-print the evaluation result
    %
    % fid ... (optional) File identifier from fopen(), if omitted, the
    %         result is printed to stdout 
    function result = print(obj,fid)
      % check EvalResultContainer list
      if isempty(obj.Container)
        error('EvalPrintLaTeX:NoData','You have to add at least one EvalResult object before you print it.\n');
      end
      % file descriptor
      if nargin == 1
        fid = 1;  % default to stdout
      end
      % header
      obj.PrintHeader(fid);
      % table
      obj.PrintTable(fid);
      % graph setup
      obj.GraphXScale     = '15mm';
      obj.GraphBarWidth   = '8mm';
      ShortTitles = obj.LaTeXStr({obj.Container.ShortTitle});
      YBar=zeros(1,length(obj.Container));
      YMin=zeros(1,length(obj.Container));
      YMax=zeros(1,length(obj.Container));
      YValue=cell(1,length(obj.Container));
      % amp_median
      for i=1:length(obj.Container)
        YBar(i) = obj.Container(i).EvalResult.pkpk.median;
        YMin(i) = obj.Container(i).EvalResult.pkpk.min;
        YMax(i) = obj.Container(i).EvalResult.pkpk.max;
        YValue{i} = FACET.FloatToString(YBar(i),3);
      end
      obj.PrintGraph(fid,'Pkpk',ShortTitles,'Median pk-pk / $\mu$V',YBar,YMin,YMax,YValue);
      % rms_residual
      for i=1:length(obj.Container)
        YBar(i) = obj.Container(i).EvalResult.rms_residual.mean;
        YMin(i) = obj.Container(i).EvalResult.rms_residual.min;
        YMax(i) = obj.Container(i).EvalResult.rms_residual.max;
        YValue{i} = FACET.FloatToString(YBar(i),3);
      end
      obj.PrintGraph(fid,'RmsResidual',ShortTitles,'RMS Corrected to Unimpaired',YBar,YMin,YMax,YValue);
      % rms_correction
      for i=1:length(obj.Container)
        YBar(i) = obj.Container(i).EvalResult.rms_correction.mean;
        YMin(i) = obj.Container(i).EvalResult.rms_correction.min;
        YMax(i) = obj.Container(i).EvalResult.rms_correction.max;
        YValue{i} = FACET.FloatToString(YBar(i),3);
      end
      obj.PrintGraph(fid,'RmsCorrection',ShortTitles,'RMS Uncorrected to Corrected',YBar,YMin,YMax,YValue);
      % snr_residual
      for i=1:length(obj.Container)
        if isempty(obj.Container(i).EvalResult.snr_residual.min)
          % no positive SNR value available
          YBar(i) = 0;
          YMin(i) = 0;
          YMax(i) = 0;
          YValue{i} = 'none';
        else
          YBar(i) = obj.Container(i).EvalResult.snr_residual.mean;
          YMin(i) = obj.Container(i).EvalResult.snr_residual.min;
          YMax(i) = obj.Container(i).EvalResult.snr_residual.max;
          YValue{i} = sprintf('%s (%d)',FACET.FloatToString(YBar(i),3),sum(obj.Container(i).EvalResult.snr_residual.data>=0));
        end
      end
      obj.PrintGraph(fid,'SnrResidual',ShortTitles,'SNR of Corrected',YBar,YMin,YMax,YValue);
      % fft_allen
      L=size(obj.Container(1).EvalResult.fft_allen.medians,2);
      YBar        = zeros(length(obj.Container),L);
      YMin        = zeros(length(obj.Container),L);
      YMax        = zeros(length(obj.Container),L);
      YValue      = cell (length(obj.Container),L);
      XTickLabels = cell(1,L);
      % note: we use the frequencies defined by the first EvalResult set
      for i=1:L
        XTickLabels{i}=sprintf('%1.1f -- %1.1f\\,Hz',...
          obj.Container(1).EvalResult.fft_allen.freqs(i),...
          obj.Container(1).EvalResult.fft_allen.freqs(i+1));
      end
      for i=1:L
        for j=1:length(obj.Container)
          YBar  (j,i) = obj.Container(j).EvalResult.fft_allen.medians(i);
          YMin  (j,i) = NaN;
          YMax  (j,i) = NaN;
          YValue{j,i} = FACET.FloatToString(YBar(j,i),2);
        end
      end
      FGraphBarWidth = 4.5;   % Unit: "mm"
      obj.GraphXScale     = sprintf('%.2fmm',(length(obj.Container)+1.3)*FGraphBarWidth);
      obj.GraphBarWidth   = sprintf('%.2fmm',FGraphBarWidth);
      obj.PrintGraph(fid,'FftAllen',XTickLabels,'Median Residual Activity / \%',YBar,YMin,YMax,YValue,ShortTitles);
      % fft_allen
      L=size(obj.Container(1).EvalResult.fft_niazy.sratios,2);
      YBar        = zeros(length(obj.Container),L);
      YMin        = zeros(length(obj.Container),L);
      YMax        = zeros(length(obj.Container),L);
      YValue      = cell (length(obj.Container),L);
      XTickLabels = cell(1,L);
      % note: we use the frequencies defined by the first EvalResult set
      for i=1:L
        XTickLabels{i}=sprintf('%1.2f\\,Hz',...
          obj.Container(1).EvalResult.fft_niazy.sfreqs (i));
      end
      for i=1:L
        for j=1:length(obj.Container)
          YBar(j,i)   = -obj.Container(j).EvalResult.fft_niazy.smean(i);
          YMin(j,i)   = NaN;
          YMax(j,i)   = NaN;
          YValue{j,i} = FACET.FloatToString(YBar(j,i),2);
        end
      end
      FGraphBarWidth = 4.5;   % Unit: "mm"
      obj.GraphXScale     = sprintf('%.2fmm',(length(obj.Container)+1.3)*FGraphBarWidth);
      obj.GraphBarWidth   = sprintf('%.2fmm',FGraphBarWidth);
      obj.PrintGraph(fid,'FftNiazy',XTickLabels,'Power Density Reduction / dB',YBar,YMin,YMax,YValue,ShortTitles);
      % Return nothing, we will not be called in a one-line command
      result = [];
    end

    function PrintHeader(obj,fid)
      fprintf(fid,'%% Auto-generated with EvalPrintLaTeX      %s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'));
      fprintf(fid,'%%\n');
      v=ver('MATLAB');
      v2=version();
      a=computer('arch');
      fprintf(fid,'%% Running %s %s %s (%s)\n',v.Name,v2,v.Date,a);
      fprintf(fid,'%%\n');
      fprintf(fid,'%% Datasets:\n');
      for i=1:length(obj.Container)
        fprintf(fid,'%%   Variable: ''%s'', Short: ''%s''\n',obj.Container(i).InputName,obj.Container(i).ShortTitle);
      end
      fprintf(fid,'%%\n');
      fprintf(fid,'%% Public properties:\n');
      fprintf(fid,'%%   CmdPrefix = ''%s''\n',obj.CmdPrefix);
      fprintf(fid,'%%\n');
      fprintf(fid,'%% Private properties:\n');
      fprintf(fid,'%%   GraphHeight     = ''%s''\n',obj.GraphHeight);
      fprintf(fid,'%%   GraphXScale     = ''%s''\n',obj.GraphXScale);
      fprintf(fid,'%%   GraphBarWidth   = ''%s''\n',obj.GraphBarWidth);
      fprintf(fid,'%%   GraphLineStyles = {''%s''}\n',FACET.StrJoin(''',''',obj.GraphLineStyles{:}));
      fprintf(fid,'%%   GraphFillStyles = {''%s''}\n',FACET.StrJoin(''',''',obj.GraphFillStyles{:}));
      fprintf(fid,'%%   GraphErrorBars  = %s\n',obj.Bool2Str(obj.GraphErrorBars));
      fprintf(fid,'%%\n');
      fprintf(fid,'%% Re-run with\n');
      fprintf(fid,'%% >> epl=FACET.EvalPrintLaTeX();\n');
      for i=1:length(obj.Container)
        fprintf(fid,'%% >> epl.AddResult(FACET.EvalResultContainer(%s,''%s''));\n',obj.Container(i).InputName,obj.Container(i).ShortTitle);
      end
      fprintf(fid,'%% >> epl.CmdPrefix = ''%s'';\n',obj.CmdPrefix);
      if fid == 1
        % printing to stdout
        fprintf(fid,'%% >> epl.print();\n');
      else
        % printing to a real file
        [filename, permission, machineformat, encoding] = fopen(fid); % retrieve info about open file
        fprintf(fid,'%% >> fid=fopen(''%s'',''w''); epl.print(fid); fclose(fid);\n',filename);
      end
      fprintf(fid,'%%\n');
      fprintf(fid,'\n');
    end

    function PrintTable(obj,fid)
      % enclosing LaTeX command
      if ~isempty(obj.CmdPrefix)
        fprintf(fid,'\\newcommand{\\%sTable}{\n',obj.CmdPrefix);
      end
      % table
      fprintf(fid,'  \\begin{tabular}{l%s}\n',repmat('r',length(obj.Container),1));
      % table header
      fprintf(fid,'        ');
      S = obj.LaTeXStr({obj.Container.ShortTitle});
      fprintf(fid,'& %s ',S{:});
      fprintf(fid,'\\\\\n');
      fprintf(fid,'    \\hline\n');
      fprintf(fid,'    \\hline\n');
      % amp_allen
      fprintf(fid,'    Median Imaging Artifact (\\uV)    ');
      for i=1:length(obj.Container)
        fprintf(fid,'& %s ',FACET.FloatToString(obj.Container(i).EvalResult.pkpk.median,3,5));
      end
      fprintf(fid,'\\\\\n');
      fprintf(fid,'    \\hline\n');
      % rms_residual
      fprintf(fid,'    RMS Corrected to Unimpaired      ');
      for i=1:length(obj.Container)
        fprintf(fid,'& %s ',FACET.FloatToString(obj.Container(i).EvalResult.rms_residual.mean,3,5));
      end
      fprintf(fid,'\\\\\n');
      fprintf(fid,'    \\hline\n');
      % rms_correction
      fprintf(fid,'    RMS Uncorrected to Corrected     ');
      for i=1:length(obj.Container)
        fprintf(fid,'& %s ',FACET.FloatToString(obj.Container(i).EvalResult.rms_correction.mean,3,5));
      end
      fprintf(fid,'\\\\\n');
      fprintf(fid,'    \\hline\n');
      % snr_residual
      fprintf(fid,'    SNR of Corrected                 ');
      for i=1:length(obj.Container)
        fprintf(fid,'& %s (%d) ',FACET.FloatToString(obj.Container(i).EvalResult.snr_residual.mean,3,5),sum(obj.Container(i).EvalResult.snr_residual.data>=0));
      end
      fprintf(fid,'\\\\\n');
      fprintf(fid,'    \\hline\n');
      % fft_allen
      fprintf(fid,'    Median Residual Activity\\\\\n');
      fprintf(fid,'    \\multirow{4}{*}{\n');
      fprintf(fid,'      \\begin{tabular}{r@{ }c@{ }r}\n');
      % note: we use the frequencies defined by the first EvalResult set
      for i = 1:length(obj.Container(1).EvalResult.fft_allen.medians)
        fprintf(fid,'       %4.1f &--& %4.1f\\,Hz \\\\\n',...
          obj.Container(1).EvalResult.fft_allen.freqs(i),...
          obj.Container(1).EvalResult.fft_allen.freqs(i+1));
      end
      fprintf(fid,'      \\end{tabular}\n');
      fprintf(fid,'    }\n');
      for j = 1:length(obj.Container(1).EvalResult.fft_allen.medians)
        fprintf(fid,'      ');
        for i=1:length(obj.Container)
          fprintf(fid,'& %s\\,\\%% ',FACET.FloatToString(obj.Container(i).EvalResult.fft_allen.medians(j),2,6));
        end
        fprintf(fid,'\\\\\n');
      end
      fprintf(fid,'    \\hline\n');
      % fft_niazy: Slice Frequency
      fprintf(fid,'    Power Density at Slice Frequency & \\\\ \n');
      fprintf(fid,'    \\multirow{4}{*}{\n');
      fprintf(fid,'      \\begin{tabular}{r@{ }r}\n');
      for j = 1:size(obj.Container(1).EvalResult.fft_niazy.sratios,2)
        fprintf(fid,'        %d: & %6.2f\\,Hz \\\\\n',...
          j,...
          obj.Container(1).EvalResult.fft_niazy.sfreqs (j));
      end
      fprintf(fid,'      \\end{tabular}\n');
      fprintf(fid,'    }\n');
      for j = 1:size(obj.Container(1).EvalResult.fft_niazy.sratios,2)
        fprintf(fid,'      ');
        for i=1:length(obj.Container)
          fprintf(fid,'& %s\\,dB ',FACET.FloatToString(obj.Container(i).EvalResult.fft_niazy.smean(j),2,6));
        end
        fprintf(fid,'\\\\\n');
      end
      fprintf(fid,'  \\end{tabular}\n');
      if ~isempty(obj.CmdPrefix)
        fprintf(fid,'}\n');
      end
    end

    function PrintGraph(obj,fid,FigurePrefix,XTickLabels,YLabel,YBar,YMin,YMax,YValue,Legend)
      if nargin==9
        Legend=[];
      end
      % enclosing LaTeX command
      if ~isempty(obj.CmdPrefix)
        fprintf(fid,'\\newcommand{\\%s%sFigure}{\n',obj.CmdPrefix,FigurePrefix);
      end
      % TikZ external file name beautification
      fprintf(fid,'  \\tikzsetfigurename{%s%s}\n',obj.CmdPrefix,FigurePrefix);
      % figure
      fprintf(fid,'  \\begin{tikzpicture}\n');
      fprintf(fid,'    \\begin{axis}[\n');
      fprintf(fid,'      %%%% coordinate boundaries\n');
      fprintf(fid,'      %%xmin = 0,\n');
      fprintf(fid,'      %%xmax = 4,\n');
      fprintf(fid,'      ymin = 0,\n');
      fprintf(fid,'      %%ymax = 75,\n');
      fprintf(fid,'      %%%% set overall figure size\n');
      fprintf(fid,'      x=%1$s,        %% x axis: 1.0 = %1$s\n',obj.GraphXScale);
      fprintf(fid,'      height=%s,   %% total height\n',obj.GraphHeight);
      fprintf(fid,'      scale only axis,\n');
      fprintf(fid,'      %%%% axis, ticks and labels\n');
      fprintf(fid,'      enlarge x limits={true,abs value=0.5},   %% append 0.5 at both sides\n');
      fprintf(fid,'      xticklabels={{%s}},\n',FACET.StrJoinCell('},{',XTickLabels));
      fprintf(fid,'      ticks=major,\n');
      fprintf(fid,'      xtick=data,\n');
      fprintf(fid,'      every major x tick/.style={white},   %% remove X tick labels, any better idea? Note: acroread doesn''t like "line width=-2"\n');
      fprintf(fid,'      ylabel={%s},\n',YLabel);
      fprintf(fid,'      %% legend\n');
      fprintf(fid,'      legend cell align=left,\n');
      fprintf(fid,'      %% plot type\n');
      fprintf(fid,'      ybar,\n');
      fprintf(fid,'      bar width=%s\n',obj.GraphBarWidth);
      fprintf(fid,'      ]\n');
      for j=1:size(YBar,1)
        fprintf(fid,'      \\addplot[\n');
        fprintf(fid,'        draw=%s,\n',obj.GraphLineStyles{mod(j-1,length(obj.GraphLineStyles))+1});
        fprintf(fid,'        fill=%s,\n',obj.GraphFillStyles{mod(j-1,length(obj.GraphFillStyles))+1});
        fprintf(fid,'        %% print value on top \n');
        fprintf(fid,'        nodes near coords,   \n');
        fprintf(fid,'        point meta=explicit symbolic,   %% replace default value with custom text, see pgfplots.pdf p. 61\n');
        if obj.GraphErrorBars && (sum(~isnan(YMax(j,:))) > 0)
          fprintf(fid,'        %%%% error bars\n');
          fprintf(fid,'        error bars/.cd, y dir=plus, y explicit, /tikz/mark size=3mm\n');
        end
        fprintf(fid,'        ]\n');
        fprintf(fid,'        coordinates {\n');
        for i=1:size(YBar,2)
          if ~isnan(YMax(j,i)) && obj.GraphErrorBars
            fprintf(fid,'          (%d,%1.4f) +- (0,%1.4f)  [%s]\n',i,YBar(j,i),YMax(j,i)-YBar(j,i),YValue{j,i});
          else
            fprintf(fid,'          (%d,%1.4f) [%s]\n',i,YBar(j,i),YValue{j,i});
          end
        end
        fprintf(fid,'        };\n');
        if sum(~isnan(YMin(j,:))) == 0
          continue
        end
        if obj.GraphErrorBars && (sum(~isnan(YMin(j,:))) > 0)
          fprintf(fid,'      %% error bars to minimum\n');
          fprintf(fid,'      \\addplot+[\n');
          fprintf(fid,'        color=black,\n');
          fprintf(fid,'        only marks,\n');
          fprintf(fid,'        no markers,\n');
          % using "forget plot" will shift the lower error-bar to the right, seems a bug :-(
          %fprintf(fid,'        forget plot,    %% don''t show a legend for this plot\n');
          fprintf(fid,'        error bars/.cd, y dir=minus, y explicit, /tikz/mark size=3mm\n');
          fprintf(fid,'        ]\n');
          fprintf(fid,'        coordinates {\n');
          for i=1:size(YBar,2)
            if ~isnan(YMin(j,i))
              fprintf(fid,'          (%d,%1.4f) +- (0,%1.4f)\n',i,YBar(j,i),YBar(j,i)-YMin(j,i));
            else
              fprintf(fid,'          (%d,%1.4f)\n',i,YBar(j,i));
            end
          end
          fprintf(fid,'        };\n');
        end
      end
      if ~isempty(Legend)
        fprintf(fid,'    \\legend{%s}\n',FACET.StrJoin(',',Legend{:}));
      end
      fprintf(fid,'    \\end{axis}\n');
      fprintf(fid,'  \\end{tikzpicture}\n');      
      if ~isempty(obj.CmdPrefix)
        fprintf(fid,'}\n');
      end
    end

    function StrOut = LaTeXOneStr(obj,StrIn)
      StrOut = strrep(StrIn, '_','\_');
      StrOut = strrep(StrOut,'#','\#');
      StrOut = strrep(StrOut,'$','\$');
      StrOut = strrep(StrOut,'{','\{');
    end

    function CellOut = LaTeXStr(obj,CellIn)
      CellOut = CellIn;
      for i = 1:length(CellIn)
        CellOut(i) = {obj.LaTeXOneStr(CellIn{i})};
      end
    end
    
    function st = Bool2Str(obj,Bool)
      if Bool
        st = 'true';
      else
        st = 'false';
      end
    end

  end

end
