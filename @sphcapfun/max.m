function varargout = max(varargin)
%MAX   Maximum value of a SPHCAPFUN in one direction.
%   MAX(f) returns a chebfun representing the maximum of the SPHCAPFUN along 
%   the angular direction, i.e, MAX(f) = @(theta) max( f ( theta, : ) ).
%
%   MAX(f, [], dim) returns a CHEBFUN representing the maximum of f along
%   direction DIM. DIM = 1 is used when computing max along the 
%   angular-direction and DIM = 2 along the radial-direction.
%
%   WARNING: This function is not always accurate to the expected precision.
% 
%   For the global maximum use MAX2.
%
% See also SPHCAPFUN/MIN, SPHCAPFUN/MAX2, SPHCAPFUN/MIN2, SPHCAPFUN/MINANDMAX2.

% Copyright 2017 by The University of Oxford and The Chebfun Developers.
% See http://www.chebfun.org/ for Chebfun information.

[varargout{1:nargout}] = max@separableApprox(varargin{:});

end
