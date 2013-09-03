%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create LaTeX code for a TikZ scatter plot of a Matrix
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
%
% Usage:
%   % create a map for a Karnough-Veitch matrix
%   KV=FACET.KVMap(2);
%   % create a Matrix2PGFPlots object
%   m2pp=FACET.Matrix2PGFPlots();
%   % add data
%   m2pp.AddMatrix(cell2mat(DAData.Container.GetPkPkMedian   (KV)),'Median Imaging Artifact');
%   m2pp.AddMatrix(cell2mat(DAData.Container.GetRMSResidual  (KV)),'RMS Corrected to Unimpaired');
%   m2pp.AddMatrix(cell2mat(DAData.Container.GetRMSCorrection(KV)),'RMS Uncorrected to Corrected');
%   m2pp.AddMatrix(cell2mat(DAData.Container.GetSNRResidual  (KV)),'SNR of Corrected');
%   % set colors of sub-plots
%   m2pp.FillColor{1} = 'red!30!white';  % the nearer to EEG/EMG values the better, here: the lower the better
%   m2pp.FillColor{2} = 'red!30!white';  % the nearer to 1.0 the better, here: the lower the better
%   m2pp.FillColor{3} = 'green!50!white';  % the larger the better
%   m2pp.FillColor{4} = 'green!50!white';  % the larger the better
%   % specify grouping of sub-plots
%   m2pp.GroupCols = 2;
%   m2pp.GroupRows = 2;
%   % specify labels for X and Y axis
%   m2pp.XLabels = DAData.Container.GetOptions(KV(1,:));
%   m2pp.YLabels = DAData.Container.GetOptions(KV(:,1));
%   % specify title for the whole images
%   m2pp.MainTitle = 'Main Title';
%   % set width of sub-plot, height will be calculated automatically (Unit: "mm")
%   m2pp.Width = 30;
%   % set LaTeX command
%   m2pp.Cmd = 'Test';
%   % print to screen
%   m2pp.print(1);
%   % print to file
%   fid=fopen('/tmp/test.inc.tex','w'); m2pp.print(fid); fclose(fid);
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Matrix2PGFPlots < handle

  %%% Configuration Values

  properties(Access=public,Dependent)
    % width of a single diagram (Unit: "mm")
    Width;
  end
  properties(GetAccess=public,SetAccess=protected,Dependent)
    % height of a single diagram (Unit: "mm")
    Height;
  end
  properties(Access=public)
    % title of the whole diagram
    MainTitle;

    % default fill color for the data squares
    DefaultFillColor = 'green!50!white';
    
    % labels along the X axis, must be a cell array of Cols strings or cell
    % arrays
    XLabels;
    % labels along the Y axis, must be a cell array of Rows strings or cell
    % arrays
    YLabels;
    % if the elements of XLabels or YLabels are cell arrays, they will be
    % concatenated with the LabelGlue using StrJoinCell()
    LabelGlue    = ', ';
    % text width of tick labels at the X axis (printed below the diagrams)
    % (Unit: "em")
    XLabelWidth  = 8.8; 
    % text width of tick labels at the Y axis (printed left of the
    % diagrams) (Unit: "em")
    YLabelWidth  = 7.3;
    % debug aid: a green box is printed around every label
    ShowLabelBox = false;

    % number of diagrams in X
    GroupCols    = 1;
    % number of diagrams in Y
    GroupRows    = 1;
    % horizontal separation between diagrams (Unit: "mm")
    GroupSepX    =  4.0;
    % vertical separation between diagrams (Unit: "mm")
    GroupSepY    = 12.0;

    % LaTeX command, within which the image is printed
    Cmd;
    % include a TikZ command to rebuild this image (if images are
    % externalized)
    ForceRemake  = true;
  end

  properties(GetAccess=public,SetAccess=protected)
    % number of matrices
    NumMatrices = 0;
    % cell array of matrices
    Matrix    = {};
    % cell array of minimum values
    Min       = {};
    % cell array of maximum values
    Max       = {};
    % cell array of titles
    Title     = {};
  end
  properties(GetAccess=public,SetAccess=public)
    % cell array with fill color, use TikZ color expressions
    FillColor = {};
  end
  properties(GetAccess=public,SetAccess=protected)
    % columns in the matrices, set by the first call to AddMatrix
    Cols;
    % rows in the matrices, set by the first call to AddMatrix
    Rows;
  end

  % internal values of properties with getters/setters
  properties(Access=protected)
    % internal stirage of Width (Unit: "mm"(
    RealWidth = 50;
  end

  methods(Access=public)

    % Constructor
    %
    function obj=Matrix2PGFPlots()
    end

    % Add a data matrix
    %
    % Parameters:
    %   Matrix  data matrix
    %   Title   title for this matrix (optional)
    %   Min     minimum value to draw as 0-size square (optional)
    %   Max     maximum value to draw as full-size square (optional)
    %
    % The default title is '(n)' with n being a consecutive number
    %
    % The default values for Min and Max are 10% of the total value range
    % of Matrix below and above the real minimum and maximum values.
    %
    function AddMatrix(obj,Matrix,varargin)
      if obj.NumMatrices == 0
        % first matrix: save its size
        [obj.Rows obj.Cols] = size(Matrix);
      else
        % check that the new matrix has the same dimension as the previous
        % ones
        if [obj.Rows obj.Cols] ~= size(Matrix)
          error('FACET:Matrix2PGFPlots:AddMatrix:Dimension','All matrices must have the same dimension');
        end
      end
      % increment counter
      obj.NumMatrices = obj.NumMatrices + 1;
      % append to internal arrays
      obj.Matrix = { obj.Matrix{:} Matrix };
      % use 5% below minimum and 5% above maximum
      MMin = min(Matrix(:));
      MMax = max(Matrix(:));
      Diff=MMax-MMin;
      MMin = MMin - 0.10*Diff;
      MMax = MMax + 0.10*Diff;
      obj.Min       = { obj.Min{:}        MMin };
      obj.Max       = { obj.Max{:}        MMax };
      obj.Title     = { obj.Title{:}      sprintf('(%d)',obj.NumMatrices) };
      obj.FillColor = { obj.FillColor{:}  obj.DefaultFillColor };
      % use optional parameters
      if nargin >= 3
        obj.Title{end} = varargin{1};
      end
      if nargin >= 4
        obj.Min{end} = varargin{2};
      end
      if nargin >= 5
        obj.Max{end} = varargin{3};
      end
    end

    % Write LaTeX code to file descriptor fid
    %
    % Use fid=1 to print to stdout
    %
    function print(obj,fid)
      % check that data is available
      if obj.NumMatrices == 0
        error('FACET:Matrix2PGFPlots:print:NoData','Cannot print() without data');
      end
      % check element count of XLabels and YLabels
      if length(obj.XLabels) ~= obj.Cols
        error('FACET:Matrix2PGFPlots:print:XLabels','XLabels must be a cell array with exactly %d elements',obj.Cols);
      end
      if length(obj.YLabels) ~= obj.Rows
        error('FACET:Matrix2PGFPlots:print:XLabels','YLabels must be a cell array with exactly %d elements',obj.Rows);
      end
      % check group size
      if obj.NumMatrices > obj.GroupCols*obj.GroupRows
        error('FACET:Matrix2PGFPlots:print:Group','Group size %d x %d too small for %d matrices',obj.GroupCols,obj.GroupRows,obj.NumMatrices);
      end

      %%% derive values from configuration
      if obj.ShowLabelBox
        ShowLabelBoxOpt = ',fill=green';
      else
        ShowLabelBoxOpt = '';
      end
      % prepare XTick coords and label strings
      XTickCoords      = cell(1,obj.Cols);
      XTickExtraCoords = cell(1,obj.Cols-1);
      for i = 1:obj.Cols
        XTickCoords     {i} = int2str(i);
      end
      for i = 1:obj.Cols-1
        XTickExtraCoords{i} = num2str(i+0.5);
      end
      XTickCoords      = FACET.StrJoinCell(',',XTickCoords);
      % if XLabels is a cell array of cell arrays, first convert the
      % inner-most arrays to strings
      if iscell(obj.XLabels{1})
        XTicks = cell(1,obj.Cols);
        for i=1:obj.Cols
          XTicks{i} = FACET.StrJoinCell(obj.LabelGlue,obj.XLabels{i});
        end
      else
        XTicks = obj.XLabels;
      end
      XTickLabels      = FACET.StrJoinCell('},{',XTicks);
      XTickExtraCoords = FACET.StrJoinCell(',',XTickExtraCoords);
      XTickExtraLabels = repmat(',',1,obj.Cols-2);
      % prepare YTick coords and label strings
      YTickCoords = cell(1,obj.Rows);
      YTickExtraCoords = cell(1,obj.Rows-1);
      for i = 1:obj.Rows
        YTickCoords     {i} = int2str(i);
      end
      for i = 1:obj.Rows-1
        YTickExtraCoords{i} = num2str(i+0.5);
      end
      YTickCoords      = FACET.StrJoinCell(',',YTickCoords);
      % if YLabels is a cell array of cell arrays, first convert the
      % inner-most arrays to strings
      if iscell(obj.YLabels{1})
        YTicks = cell(1,obj.Rows);
        for i=1:obj.Cols
          YTicks{i} = FACET.StrJoinCell(obj.LabelGlue,obj.YLabels{i});
        end
      else
        YTicks = obj.XLabels;
      end
      YTickLabels      = FACET.StrJoinCell('},{',{YTicks{end:-1:1}});
      YTickExtraCoords = FACET.StrJoinCell(',',YTickExtraCoords);
      YTickExtraLabels = repmat(',',1,obj.Rows-2);
      % enclosing LaTeX command
      if ~isempty(obj.Cmd)
        fprintf(fid,'\\newcommand{\\%s}{\n',obj.Cmd);
      end
      % TikZ external file name beautification
      fprintf(fid,'  \\tikzsetfigurename{%s}\n',obj.Cmd);
      fprintf(fid,'  ');
      if ~obj.ForceRemake
        fprintf(fid,'%% ');
      end
      fprintf(fid,'\\tikzset{external/force remake}   %% remake this one image\n');
      % figure
      fprintf(fid,'  \\begin{tikzpicture}\n');
      if obj.NumMatrices > 1
        fprintf(fid,'    \\begin{groupplot}[\n');
        fprintf(fid,'      group style={\n');
        fprintf(fid,'        group size=%d by %d,\n',obj.GroupCols,obj.GroupRows);
        fprintf(fid,'        horizontal sep=%0.2fmm,\n',obj.GroupSepX);
        fprintf(fid,'        vertical sep=%0.2fmm,\n',obj.GroupSepY);
        fprintf(fid,'        xlabels at=edge bottom,\n');
        fprintf(fid,'        ylabels at=edge left,\n');
        fprintf(fid,'        xticklabels at=edge bottom,\n');
        fprintf(fid,'        yticklabels at=edge left\n');
        fprintf(fid,'      },\n');
      else
        fprintf(fid,'    \\begin{axis}[\n');
      end
      fprintf(fid,'      scale only axis=true,\n');
      fprintf(fid,'      width=%0.2fmm,height=%0.2fmm,\n',obj.Width,obj.Height);
      fprintf(fid,'      xmin=0.5,xmax=%d.5,\n',obj.Cols);
      fprintf(fid,'      ymin=0.5,ymax=%d.5,\n',obj.Rows);
      fprintf(fid,'      x tick label style={align=flush right,text width=%0.2fem,text depth=%s,rotate=90,anchor=east},\n',obj.XLabelWidth,ShowLabelBoxOpt);
      fprintf(fid,'      y tick label style={align=flush right,text width=%0.2fem,text depth=%s},\n',obj.YLabelWidth,ShowLabelBoxOpt);
      fprintf(fid,'      xtick={%s},\n',XTickCoords);
      fprintf(fid,'      xticklabels={{%s}},\n',XTickLabels);
      fprintf(fid,'      ytick={%s},\n',YTickCoords);
      fprintf(fid,'      yticklabels={{%s}},\n',YTickLabels);
      fprintf(fid,'      extra x ticks={%s},\n',XTickExtraCoords);
      fprintf(fid,'      extra y ticks={%s},\n',YTickExtraCoords);
      fprintf(fid,'      extra x tick labels={%s},\n',XTickExtraLabels);
      fprintf(fid,'      extra y tick labels={%s},\n',YTickExtraLabels);
      fprintf(fid,'      extra x tick style={grid=minor},\n');
      fprintf(fid,'      extra y tick style={grid=minor},\n');
      fprintf(fid,'      minor grid style={black},\n');
      fprintf(fid,'      major tick length={0pt},\n');
      if ~isempty(obj.MainTitle)
        fprintf(fid,'      title={%s},\n',obj.MainTitle);
      end
      fprintf(fid,'    ]\n');
      T = '';
      for Idx = 1:obj.NumMatrices
        if obj.NumMatrices > 1
          T = sprintf('title={%s}',obj.Title{Idx});
          fprintf(fid,'      \\nextgroupplot[%s]\n',T);
        end
        fprintf(fid,'      \\addplot+[\n');
        fprintf(fid,'        scatter,\n');
        fprintf(fid,'        scatter src=explicit symbolic,\n');
        fprintf(fid,'        only marks,\n');
        fprintf(fid,'        mark=square*,\n');
        fprintf(fid,'        mark options={draw=black,fill=%s},\n',obj.FillColor{Idx});
        fprintf(fid,'        disabledatascaling,\n');
        fprintf(fid,'        scatter/@pre marker code/.code={%%\n');
        fprintf(fid,'          %% stragenly enough, multiplying the value by 50 results in an 1:1\n');
        fprintf(fid,'          %% relation to the data grid\n');
        fprintf(fid,'          %% Important: multiply by 50 at the end to avoid an overflow if large values are used\n');
        SubG = obj.Min{Idx};
        DivG = obj.Max{Idx}-SubG;
        fprintf(fid,'          \\pgfmathsetmacro\\radius{(\\pgfplotspointmeta-%0.3f)/%0.3f*50.0*\\pgfplotsunitxlength}%%\n',SubG,DivG);
        fprintf(fid,'          \\scope[mark size=\\radius]\n');
        fprintf(fid,'        },%%\n');
        fprintf(fid,'        scatter/@post marker code/.code={%%\n');
        fprintf(fid,'          \\endscope\n');
        fprintf(fid,'        },%%\n');
        fprintf(fid,'      ] coordinates {\n');
        for Row=1:obj.Rows
          for Col=1:obj.Cols
            fprintf(fid,'        (%d,%d) [%.4f]\n',Col,obj.Rows+1-Row,obj.Matrix{Idx}(Row,Col));
          end
        end
        fprintf(fid,'      };\n');
      end
      if obj.NumMatrices > 1
        fprintf(fid,'    \\end{groupplot}\n');
      else
        fprintf(fid,'    \\end{axis}\n');
      end
      fprintf(fid,'  \\end{tikzpicture}\n');      
      if ~isempty(obj.Cmd)
        fprintf(fid,'}\n');
      end
    end

  end

  % Getters and Setters
  methods

    % Setter for property Width
    function obj = set.Width(obj,Width)
      obj.RealWidth = Width;
    end
    % Getter for property Width
    function Width = get.Width(obj)
      Width = obj.RealWidth;
    end
    % getter for property Height
    function Height = get.Height(obj)
      if obj.NumMatrices == 0
        % no matrix was supplied, assume quadratic matrix
        warning('FACET:Matrix2PGFPlots:Height:NoData','No data given, assuming quadratic diagrams');
        Height = obj.RealWidth;
      else
        % at least one matrix was added, calculate height from width
        Height = obj.RealWidth * obj.Rows / obj.Cols;
      end
    end

  end

end
