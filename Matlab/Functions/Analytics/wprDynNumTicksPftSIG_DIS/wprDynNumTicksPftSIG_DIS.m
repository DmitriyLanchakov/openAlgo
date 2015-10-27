function varargout = wprDynNumTicksPftSIG_DIS(price,Mult,OB,OS,...
                                                minTick,numTicks,openAvg,...
                                                bigPoint,cost,scaling, hSub)
%WPRDYNNUMTICKSPFTSIG_DIS  Graphical display of dynamic W%R with an auto-adjusting dynamic lookback & profit
% WPRSIG_DIS Graphical display of dynamic W%R with an auto-adjusting dynamic lookback period strategy and
% achieved profit taking.
% Note that the trading signal is generated when the W%RD value is above/below the OS/OB threshold.
% Mult serves as a volatility modifier
%
%   NOTE: It is important to consider that the modified W%RD signal generator really has 3 states.
%           Above Threshold OB is Overbought
%           Below Threshold OS is Oversold
%           There is also a neutral region between +/- Threshold and 50%
%           This modified version uses a positive range for W%R contrary to the standard negative
%           implementation
%
%   This should be considered prior to adding or removing any Echos to this output.
%   For calculating a direct PNL, the signal should first be cleaned with remEcho_mex.
%
%   INPUTS:     price       	An array of price in the form [O | H | L | C]     
%               Mult            Modifier to control effective risk based on volatility. (Default: 3)
%                               The higher the value of Mult, the LESS risky. 
%                               Values over 33 are illogical
%               OB              threshold of overbought (default: 30)
%               OS              threshold of oversold (default: 70)
%               minTick         the minimum increment of the asset being analyzed
%               numTicks        the number of ticks to close a position profitably
%               openAvg         the manner in which to calculate profit targets:
%                                   0  per contract (default)
%                                   1  position average
%               scaling         sharpe ratio adjuster
%               cost            round turn commission cost for proper P&L calculation
%               bigPoint        Full tick dollar value of security
%
%   OUTPUTS:
%               SIG             The generated output SIGNAL
%               R               Return generated by the derived signal
%               SH              Sharpe ratio generated by the derived signal
%               WPR             William's Percent R values generated by the call to 'wprDynSTA.m'
%

%% Defaults
if ~exist('Mult','var'), Mult = 3; end;
if ~exist('OB','var'), OB = 30; end;
if ~exist('OS','var'), OS = 70; end;
if ~exist('bigPoint','var'), bigPoint = 1; end; 
if ~exist('cost','var'), cost = 0; end;         
if ~exist('scaling','var'), scaling = 1; end;

%% Parse


%% williams %r
[barsOut,s,r,sh] = wprDynNumTicksPftSIG(price,Mult,OB,OS,...
                                    minTick,numTicks,openAvg,...
                                    bigPoint,cost,scaling);

%NOTE:  The WPR return here is misleading as it is derived from the altered bars
%       produced from the profit taking routine. No adjustment has been made for
%       the injected artificial bars from the profit taking
[~,w] = wprDynSTA(barsOut, Mult, OB, OS);
                                
fClose = OHLCSplitter(barsOut);

%% Plot if requested
if nargout == 0
	% Center plot window basis monitor (single monitor calculation)
    scrsz = get(0,'ScreenSize');
    figure('Position',[scrsz(3)*.15 scrsz(4)*.15 scrsz(3)*.7 scrsz(4)*.7])
    
    ax(1) = subplot(3,1,1);
    plot(fClose), grid on
    axis (ax(1),'tight');
    legend('Close')
    title(['W%R Dynamic Results, Sharpe Ratio = ',num2str(sh,3)])
    
    ax(2) = subplot(3,1,2);
    plot([w,OS*ones(size(w)),OB*ones(size(w))])
    grid on
    legend(['W%RD Mult ',num2str(Mult)],['W%RD Upper ',num2str(OS),'%'],...
        ['W%RD Lower ',num2str(OB),'%'],...
        'Location', 'North')
    title(['W%R Dynamic Results, Ticks Pft = ',num2str(numTicks)])
    
    ax(3) = subplot(3,1,3);
    plot([s,cumsum(r)]), grid on
    legend('Position','Cumulative Return')
    title(['Final Return = ',thousandSepCash(sum(r))])
    linkaxes(ax,'x')
    
elseif (nargout == 0) && exist('hSub','var')% Plot as subplot
    % We pass hSub as a string so we can have asymmetrical graphs
    % The call to char() parses the passed cell array
    ax(1) = subplot(str2num(char(hSub(1))),str2num(char(hSub(2))),str2num(char(hSub(3)))); %#ok<ST2NM>
    axis (ax(1),'tight');
    plot(fClose), grid on
    axis (ax(1),'tight');
    grid on
    legend('Close')
    title(['W%R Dynamic Results, Sharpe Ratio = ',num2str(sh,3)])
    
    ax(2) = subplot(str2num(char(hSub(1))),str2num(char(hSub(2))),str2num(char(hSub(4)))); %#ok<ST2NM>
    ylim([0 100])
    axis manual;
    hold on;
    plot([w,OS*ones(size(w)),OB*ones(size(w))])
    grid on
    legend(['W%RD Mult ',num2str(Mult)],['W%RD Upper ',num2str(OS),'%'],...
        ['W%RD Lower ',num2str(OB),'%'],...
        'Location', 'North')
    title(['W%R Dynamic Results, Ticks Pft = ',num2str(numTicks)])
    
    ax(3) = subplot(str2num(char(hSub(1))),str2num(char(hSub(2))),str2num(char(hSub(5)))); %#ok<ST2NM>
    plot([s,cumsum(r)]), grid on
    legend('Position','Cumulative Return','Location','North')
    title(['Final Return = ',thousandSepCash(sum(r))])
    linkaxes(ax,'x')
else
    %% Return values
    for ii = 1:nargout
        switch ii
            case 1
                varargout{1} = s; % signal
            case 2
                varargout{2} = r; % return (pnl)
            case 3
                varargout{3} = sh; % sharpe ratio
            case 4
                varargout{4} = w; % w%r value
            otherwise
                warning('W%RD:OutputArg',...
                    'Too many output arguments requested, ignoring last ones');
        end %switch
    end %for
end %if

%%
%   -------------------------------------------------------------------------
%                                  _    _ 
%         ___  _ __   ___ _ __    / \  | | __ _  ___   ___  _ __ __ _ 
%        / _ \| '_ \ / _ \ '_ \  / _ \ | |/ _` |/ _ \ / _ \| '__/ _` |
%       | (_) | |_) |  __/ | | |/ ___ \| | (_| | (_) | (_) | | | (_| |
%        \___/| .__/ \___|_| |_/_/   \_\_|\__, |\___(_)___/|_|  \__, |
%             |_|                         |___/                 |___/
%   -------------------------------------------------------------------------
%        This code is distributed in the hope that it will be useful,
%
%                      	   WITHOUT ANY WARRANTY
%
%                  WITHOUT CLAIM AS TO MERCHANTABILITY
%
%                  OR FITNESS FOR A PARTICULAR PURPOSE
%
%                          expressed or implied.
%
%   Use of this code, pseudocode, algorithmic or trading logic contained
%   herein, whether sound or faulty for any purpose is the sole
%   responsibility of the USER. Any such use of these algorithms, coding
%   logic or concepts in whole or in part carry no covenant of correctness
%   or recommended usage from the AUTHOR or any of the possible
%   contributors listed or unlisted, known or unknown.
%
%   Any reference of this code or to this code including any variants from
%   this code, or any other credits due this AUTHOR from this code shall be
%   clearly and unambiguously cited and evident during any use, whether in
%   whole or in part.
%
%   The public sharing of this code does not relinquish, reduce, restrict or
%   encumber any rights the AUTHOR has in respect to claims of intellectual
%   property.
%
%   IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY
%   DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
%   DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
%   OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
%   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
%   STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
%   ANY WAY OUT OF THE USE OF THIS SOFTWARE, CODE, OR CODE FRAGMENT(S), EVEN
%   IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
%   -------------------------------------------------------------------------
%
%                             ALL RIGHTS RESERVED
%
%   -------------------------------------------------------------------------
%
%   Author:        Mark Tompkins
%   Revision:      4906.24976
%   Copyright:     (c)2013
%
