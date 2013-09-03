%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate a 2D matrix with indices corresponding to the elements of a
% Karnaugh-Veitch diagram.
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
% x = KVMap(Dimensions);
%   Returns a map for 2^Dimensions elements. If Dimensions is odd, the
%   map has 2x more columns than rows.
%
%   Examples:
%     x = KVMap(4) returns a 4x4 matrix
%     x = KVMap(5) returns a 4x8 matrix (4 rows, 8 columns)
%
% x = KVMap(ColDims,RowDims);
%   Returns a map with 2^ColDims columns and 2^RowDims rows.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function KV = KVMap(varargin)
  
  if nargin == 1
    % one parameter: ld(total)
    NumDims = varargin{1};
    % fold to 2 dimensions, calculate rows and columns
    ColDims = ceil (NumDims/2);
    RowDims = floor(NumDims/2);
  elseif nargin == 2
    % two parameters: ld(columns), ld(rows)
    ColDims = varargin{1};
    RowDims = varargin{2};
    NumDims = ColDims + RowDims;
  else
    error('FACET:KVMap:WrongArgumentCount','Wrong count of input arguments');
  end

  Cols = 2^ColDims;
  Rows = 2^RowDims;
  % create the result matrix
  KV = zeros(Rows,Cols);

  for Row = 1:Rows
    for Col = 1:Cols

      KV(Row,Col) = bitor(...
                     bitshift(FACET.Int2Gray(Row-1),ColDims),...
                     FACET.Int2Gray(Col-1));
    end
  end

end
