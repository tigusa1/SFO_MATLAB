function SFO_check
%----------------------------------------------------------------------------------------------
% Check the SFO algorithm
%----------------------------------------------------------------------------------------------
n_time  = 50;                                                % number of weeks

n_max = 100;

[ a,p,s_required,y0,c_store,c_cust_0,n_foods,t_ordinance,lbl_foods ] = set_parameters();

[ y_supply,s_actual,y_demand,y_cust,y_waste,s_actual_end,m_profit,c_cust ] = ...
    deal( zeros(n_time,n_foods,n_max) );

% c_cust(1:2,:)    = ones(2,1)*c_cust_0;                       % initial cost

[ s_actual_all ] = deal( zeros(n_time,1) );

c_cust_max = zeros(1, n_foods);                              % initial max price

max_profit = ones(1, n_foods) * (-10000);                                          % initial max_profit

k_max = zeros(1, n_foods);

c_custk = zeros(n_foods);
for j=1:n_foods
    for k=1:n_max
        c_cust_max(j) = y0(j) * a(j);
        c_custk(j) = c_cust_max(j) * (k-1) / n_max;
        if c_custk(j) >0
            c_custk(j) = c_custk(j);
        else
            c_custk(j) = 0;
        end
        for i=3:n_time                                               % begin at time step 3
            if i>=t_ordinance(j)
                s_required_j = s_required(j);
            else
                s_required_j = 0;
            end
            [ y_supply(i,j,k),s_actual(i,j,k),y_demand(i,j,k),y_cust(i,j,k),y_waste(i,j,k),...
                    s_actual_end(i,j,k),m_profit(i,j,k),c_cust(i,j,k) ] = ...
                    calc_foods( a(j), p(:,j), s_required_j, y0(j), c_store(j), ...
                    y_demand(i-1,j,k), s_actual_end(i-1,j,k), s_actual_all(i-2), c_custk(j) );
            s_actual_all(i) = sum(s_actual(i,:));                    % add all of s_actual
        end
%         m_profit(:,:,k)
%         c_cust(:,:)
        if m_profit(n_time-1,j,k) > max_profit(j)
            k_max(j) = k;
            max_profit(j) = m_profit(n_time-1,j,k);
        end
    end
end
% m_profit(:,1,5)
% k_max


plot_results( y_supply(:,:,k_max(1)),s_actual(:,:,k_max(1)),y_demand(:,:,k_max(1)),y_cust(:,:,k_max(1)),y_waste(:,:,k_max(1)),m_profit(:,:,k_max(1)),c_cust(:,:,k_max(1)),lbl_foods,n_foods )


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
m_profit  = c_cust_1*y_cust - y_supply*c_store - ...
    ((p(3)+2*p(4)) + p(17)*s_actual_all_2)*s_actual - (p(1) + p(2)*3)*y_supply;      %use new parameters instead of old one

