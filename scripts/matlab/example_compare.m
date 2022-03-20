clear all 
close all
m=csvread('connectome_streamline_count_10M.csv'); 

f_ends='tracks_10M_endpoints.npy';
f_atlas='native_dMRI_space_Glasser_Tian_Subcortex_S4_3T'; 

[c,unassigned]=tck2connectome(f_ends,f_atlas,'Radius',4); 

figure; 
subplot(1,2,1); imagesc(log10(c)); 
subplot(1,2,2); imagesc(log10(m)); 

ind_upper=find(triu(ones(size(c)),1));
corr(c(ind_upper),m(ind_upper)) 

