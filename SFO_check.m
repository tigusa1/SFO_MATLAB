function SFO_check
%----------------------------------------------------------------------------------------------
% Check the SFO algorithm
%----------------------------------------------------------------------------------------------
n_time  = 20;                                                % number of weeks

[ a,p,s_required,y0,c_store,c_cust_0,n_foods,t_ordinance,lbl_foods ] = set_parameters();

[ y_supply,s_actual,y_demand,y_cust,y_waste,s_actual_end,m_profit,c_cust ] = ...
    deal( zeros(n_time,n_foods) );

c_cust(1:2,:)    = ones(2,1)*c_cust_0;                       % initial cost

[ s_actual_all ] = deal( zeros(n_time,1) );

for i=3:n_time                                               % begin at time step 3
    for j=1:n_foods
        if i>=t_ordinance(j)
            s_required_j = s_required(j);
        else
            s_required_j = 0;
        end
        [ y_supply(i,j),s_actual(i,j),y_demand(i,j),y_cust(i,j),y_waste(i,j),...
            s_actual_end(i,j),m_profit(i,j),c_cust(i,j) ] = ...
            calc_foods( a(j), p(:,j), s_required_j, y0(j), c_store(j), ...
            y_demand(i-1,j), s_actual_end(i-1,j), s_actual_all(i-2), c_cust(i-1,j) );
    end
    s_actual_all(i) = sum(s_actual(i,:));                    % add all of s_actual
end

plot_results( y_supply,s_actual,y_demand,y_cust,y_waste,m_profit,c_cust,lbl_foods,n_foods )


function plot_results( y_supply,s_actual,y_demand,y_cust,y_waste,m_profit,c_cust, ...
    lbl_foods,n_foods )
%----------------------------------------------------------------------------------------------
% plot all results
%----------------------------------------------------------------------------------------------
fig = figure(100); fig.Name = 'time series'; clf
subplot(4,2,1), plot(y_supply), title('y supply')
subplot(4,2,2), plot(y_demand), title('y demand')
subplot(4,2,3), plot(y_cust),   title('y cust')
subplot(4,2,4), plot(y_waste),  title('y waste')
subplot(4,2,5), plot(s_actual), title('s actual')
subplot(4,2,6), plot(m_profit), title('m profit')
subplot(4,2,7), plot(c_cust),   title('c cust')

fig_plots = fig.Children;                                   % get all axes
num_plots = length(fig_plots);                              % number of axes
for i_plot=1:num_plots
    for j=1:n_foods
        fig_plots(i_plot).Children(j).LineWidth = 2;        % set line width of each plot
    end
end

subplot(4,2,1), legend(lbl_foods)                           % set legend for one plot
subplot(4,2,6), xlabel('weeks')
subplot(4,2,7), xlabel('weeks')


function [ a,p,s_required,y0,c_store,c_cust_0,n_foods,t_ordinance,lbl_foods ] = ...
    set_parameters()
%----------------------------------------------------------------------------------------------
% set the parameters of the foods
%----------------------------------------------------------------------------------------------
orange_par = [0.0287,-0.0010,0.0535,-0.0015,-16.5178402214775,2.79508364248950/2, 2.79508364248950/2,-0.479453242578706,0.554963737373109,1.99362694396789,1.10808182780980,( -16.5178402214775+(2.79508364248950/2+ 2.79508364248950/2-0.479453242578706+0.554963737373109+1.99362694396789+1.10808182780980)*5)/2.49,0.4550,0.0104,-0.0323, 2];
broccoli_par = [0.1455,-0.0062,0.3367,-0.0273,2.69842890949335,0.566241572059529/2, 0.566241572059529/2,0.335432030763894,0.789696747146486,0.796548752001795,-1.47023827738507,( 2.69842890949335+(0.566241572059529/2+0.566241572059529/2+0.335432030763894+0.789696747146486+0.796548752001795-1.47023827738507)*5)/2.41,0.5567,0.0565,-0.0237, 4];
CFJ_par = [0.2311,-0.0256,0.3443,-0.0291,7.46241583377826,-0.282166335872858/2, -0.282166335872858/2,-1.16520338785742,-0.300048124178850,0.939344611961531,1.27623869047736,( 7.46241583377826+(-0.282166335872858/2-0.282166335872858/2-1.16520338785742-0.300048124178850+0.939344611961531+1.27623869047736)*5)/2.31625,0.4550,0.0104,-0.0323, 5];

lbl_foods = {'Orange','Broccoli','Canned Fruit Juice'};

n_foods   = length(lbl_foods);

% [ a,s_required,y0,c_store ] = deal( ones(1,n_foods) );
[ a,s_required,y0,c_store ] = deal( [0.1866;0.3095;0.2363], [2;2;2], [13.3437;7.7868;9.8032], [0.3;0.2;1.2]);

c_cust_0  = [ 0.6 0.4 1.9 ];

t_ordinance = [ 3 5 7 ];                                     % time of ordinance

% p = ones(18,n_foods)./[10 8 5];
p = ([0.0287,-0.0010,0.0535,-0.0015,-16.5178402214775,2.79508364248950/2, 2.79508364248950/2,-0.479453242578706,0.554963737373109,1.99362694396789,1.10808182780980,( -16.5178402214775+(2.79508364248950/2+ 2.79508364248950/2-0.479453242578706+0.554963737373109+1.99362694396789+1.10808182780980)*5)/2.49,0.4550,0.0104,-0.0323, 2, 0.015, 0.02;0.1455,-0.0062,0.3367,-0.0273,2.69842890949335,0.566241572059529/2, 0.566241572059529/2,0.335432030763894,0.789696747146486,0.796548752001795,-1.47023827738507,( 2.69842890949335+(0.566241572059529/2+0.566241572059529/2+0.335432030763894+0.789696747146486+0.796548752001795-1.47023827738507)*5)/2.41,0.5567,0.0565,-0.0237, 4, 0.015, 0.02;0.2311,-0.0256,0.3443,-0.0291,7.46241583377826,-0.282166335872858/2, -0.282166335872858/2,-1.16520338785742,-0.300048124178850,0.939344611961531,1.27623869047736,( 7.46241583377826+(-0.282166335872858/2-0.282166335872858/2-1.16520338785742-0.300048124178850+0.939344611961531+1.27623869047736)*5)/2.31625,0.4550,0.0104,-0.0323, 5, 0.015, 0.02].');



function [ y_supply,s_actual,y_demand,y_cust,y_waste,s_actual_end,m_profit,c_cust ] = ...
    calc_foods( a, p, s_required, y0, c_store, ...
    y_demand_1, s_actual_end_1, s_actual_all_2, c_cust_1 )
%----------------------------------------------------------------------------------------------
% calculate y, s, m for a specific food
%----------------------------------------------------------------------------------------------
y_supply  = max([
    s_required - s_actual_end_1                              % satisfy s_required
    y_demand_1 - s_actual_end_1                              % satisfy previous week demand
    0 ]);                                                    % must be positive
s_actual  = y_supply + s_actual_end_1;                       % s at beginning of week
y_demand  = y0 - c_cust_1/a + p(18)*s_actual_all_2;          % price->decrease, s_all->increase
y_cust    = min( y_demand, s_actual );                       % min of demand and s
y_waste   = max( s_actual/p(16) - y_cust, 0 );
s_actual_end = s_actual - y_cust - y_waste;
c_cust    = c_cust_1;                                        % temporarily use constant cost
m_profit  = c_cust*y_cust - y_supply*c_store - ...
    (p(4) + p(17)*s_actual_all_2)*s_actual - p(2)*y_supply;

