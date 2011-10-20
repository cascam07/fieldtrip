function ft_multiplotCC(cfg, data)

% FT_MULTIPLOTCC visualiuzes the coherence between channels by using multiple
% topoplots. The topoplot at a given channel location shows the coherence
% of that channel with all other channels.
%
% Use as
%   ft_multiplotCC(cfg, data)
%
% See also FT_TOPOPLOTCC

% Undocumented local options:
% cfg.layout  = layout filename or a structure produced by prepare_layout
% cfg.xlim
% cfg.parameter
% This function requires input from FT_FREQSTATISTICS_SHIFTPREDICT
% This function should be rewritten, using the clean topoplot implementation

% Copyright (C) 2005-2006, Jan-Mathijs Schoffelen, Robert Oostenveld
%
% This file is part of FieldTrip, see http://www.ru.nl/neuroimaging/fieldtrip
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id$

ft_defaults

% record start time and total processing time
ftFuncTimer = tic();
ftFuncClock = clock();;
ftFuncMem   = memtic();

% check if the input cfg is valid for this function
cfg = ft_checkconfig(cfg, 'trackconfig', 'on');
cfg = ft_checkconfig(cfg, 'renamed',	 {'zparam', 'parameter'});
cfg = ft_checkconfig(cfg, 'deprecated',  {'xparam'});

% if ~isfield(cfg, 'layout'),    cfg.layout = 'CTF151s.lay';       end;
if ~isfield(cfg, 'xparam'),    cfg.xparam = 'foi';               end;
if ~isfield(cfg, 'xlim'),      cfg.xlim   = 'all';               end;
if ~isfield(cfg, 'parameter'),    cfg.parameter = 'avg.icohspctrm';    end;

% for backward compatibility with old data structures
data = ft_checkdata(data);

if strcmp(cfg.parameter, 'avg.icohspctrm') && ~issubfield(data, 'avg.icohspctrm'),
  data.avg.icohspctrm = abs(imag(data.avg.cohspctrm));
end

if strcmp(data.dimord, 'refchan_chan_freq'),
  %reshape input-data, such that ft_topoplotTFR will take it
  cnt = 1;
  siz = size(data.prob);
  data.labelcmb = cell(siz(1)*siz(2),2);
  data.prob = reshape(data.prob, [siz(1)*siz(2) siz(3)]);
  data.stat = reshape(data.stat, [siz(1)*siz(2) siz(3)]);
  for j = 1:length(data.label)
    for k = 1:length(data.reflabel)
      data.labelcmb(cnt,:) = [data.reflabel(k) data.label(j)];
      cnt = cnt + 1;
    end
  end
  tmpdata = data;
else
  dat   = getsubfield(data, cfg.parameter);
  scale = [0 max(dat(:))-0.2];
end

if isfield(cfg, 'xparam'),
  xparam = getsubfield(data, cfg.xparam);
  if ~strcmp(cfg.xlim, 'all'),
    fbin = [nearest(xparam, cfg.xlim(1)) nearest(xparam, cfg.xlim(2))];
  else
    fbin = [xparam(1) xparam(end)];
  end
end

% Read or create the layout that will be used for plotting
lay = ft_prepare_layout(cfg, varargin{1});
cfg.layout = lay;
ft_plot_lay(lay, 'box', false,'label','no','point','no');

[chNum,X,Y,Width,Height,Lbl] = textread(cfg.layout,'%f %f %f %f %f %s');

xScaleFac = 1/(max(Width)+ max(X) - min(X));
yScaleFac = 1/(max(Height)+ max(Y) - min(Y));


Xpos = xScaleFac*(X-min(X));
Ypos = 0.9*yScaleFac*(Y-min(Y));

for k=1:length(chNum) - 2
  subplotOL('position',[Xpos(k) Ypos(k)+(Height(k)*yScaleFac) Width(k)*xScaleFac*2 Height(k)*yScaleFac*2])
  config.layout     = cfg.layout;
  if exist('tmpdata'),

    config.style      = 'straight';
    config.marker     = 'off';
    try, config.refmarker = strmatch(Lbl(k), data.reflabel);
    catch, config.refmarker  = strmatch(Lbl(k), data.label); end
    config.interplimits = 'electrodes';
    if isfield(cfg, 'xparam'),
      config.xparam = cfg.xparam;
      config.xlim   = xparam;
    else
      config.xparam = 'time';
      config.xlim   = [k-0.5 k+0.5];
    end
    config.parameter = cfg.parameter;
    config.refchannel = Lbl(k);
    config.colorbar = 'no';
    config.zlim     = scale;
    config.grid_scale = 30;
    ft_topoplotTFR(config, data);
    drawnow;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% deal with the output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the output cfg
cfg = ft_checkconfig(cfg, 'trackconfig', 'off', 'checksize', 'yes');

% add the version details of this function call to the configuration
cfg.version.name = mfilename('fullpath'); % this is helpful for debugging
cfg.version.id   = '$Id$'; % this will be auto-updated by the revision control system

% add information about the Matlab version used to the configuration
cfg.callinfo.matlab = version();

% add information about the function call to the configuration
cfg.callinfo.proctime = toc(ftFuncTimer);
cfg.callinfo.procmem  = memtoc(ftFuncMem);
cfg.callinfo.calltime = ftFuncClock;
cfg.callinfo.user = getusername(); % this is helpful for debugging
fprintf('the call to "%s" took %d seconds and an estimated %d MB\n', mfilename, round(cfg.callinfo.proctime), round(cfg.callinfo.procmem/(1024*1024)));

