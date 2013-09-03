%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PCA_CALC   Principal Component Analysis
%
% Author: Rami K. Niazy, FMRIB Centre, University of Oxford
%
% Copyright (c) 2004 University of Oxford.
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
function [EVec, Eload, EVal] = CalcPCA(vecs)
%
%  PCA_CALC   Principal Component Analysis
%
%   [EVEC, ELOAD, EVAL] = PCA_CALC(X) takes a column-wise de-meaned
%       data matrix X of size n-by-m and calculates the n
%       Eigenvectors (EVEC of size n-by-n) of the data covariance
%       matrix, the factor loadings (ELOAD of size n-by-m) and the
%       corresponding Eigenvalues (EVAL of size n-by-1).
%
%
%

[m,n]=size(vecs);
[Us,S,EVec] = svd(vecs,0);

if m == 1
    S = S(1);
else
    S = diag(S);
end
Eload = Us .* repmat(S',m,1);
S = S ./ sqrt(m-1);   
if m <= n
    S(m:n,1) = 0;
    S(:,m:n) = 0;
end
EVal = S.^2;
