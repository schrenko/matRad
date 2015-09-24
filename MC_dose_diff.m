function [D_Diff_pos,D_Diff_neg] = MC_dose_diff(D_1,D_2,PLAN,CT,cuttoff,absorreal)



if absorreal == 0
D_Diff = D_1-D_2; %absolute diff
end
if absorreal == 1
D_Diff = ((D_1-D_2)./D_1)*100; %rel. diff
end
 
                     
                     

 for v=1:1:PLAN.voxelDimensions(3)
          for j=1:1:PLAN.voxelDimensions(2)
                 for i=1:1:PLAN.voxelDimensions(1)
                
          
                   if  D_Diff(j,i,v)> 0 && D_Diff(j,i,v) < cuttoff
                       
                       D_Diff_pos(j,i,v) = D_Diff(j,i,v);
                       
                   elseif D_Diff(j,i,v) > cuttoff
                       
                       D_Diff_pos(j,i,v) = cuttoff;
       
                   else    
                       D_Diff_pos(j,i,v) = 0;
                  
                   end
                   
                   if  D_Diff(j,i,v)<0 && D_Diff(j,i,v)> -cuttoff
                       
                       D_Diff_neg(j,i,v) = abs(D_Diff(j,i,v));
                       
                   elseif D_Diff(j,i,v)< -cuttoff
                       
                       D_Diff_pos(j,i,v) = cuttoff;
                                     
                   else
                       D_Diff_neg(j,i,v) = 0;
                   end    
                 end 
           end
end
          
%zero in AIR 
for v=1:1:PLAN.voxelDimensions(3)
     for j=1:1:PLAN.voxelDimensions(2)
            for i=1:1:PLAN.voxelDimensions(1)
 
                 if CT.cube(j,i,v) <= 0.04   
                 D_Diff_neg(j,i,v) = 0;
                 D_Diff_pos(j,i,v) = 0;
                 end
                
            end
       end
 end             