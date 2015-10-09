function [D_Diff_pos,D_Diff_neg] = MC_DoseDifference(D_1,D_2,PLAN,cuttoff,absorreal)

if absorreal == 0
D_Diff = D_1-D_2; %absolute diff

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




end

if absorreal == 1
D_Diff = ((D_1-D_2)./D_1)*100; %rel. diff


for v=1:1:PLAN.voxelDimensions(3)
          for j=1:1:PLAN.voxelDimensions(2)
                 for i=1:1:PLAN.voxelDimensions(1)
                
          if D_2(j,i,v) == 0 
                     
           D_Diff_pos(j,i,v) = 0;
           D_Diff_neg(j,i,v) = 0;

          else
           if  D_Diff(j,i,v)> 0 && D_Diff(j,i,v) < cuttoff
                       
                       D_Diff_pos(j,i,v) = D_Diff(j,i,v);
                       
                   elseif D_Diff(j,i,v) > cuttoff
                       
                       D_Diff_pos(j,i,v) = cuttoff;
       
                   else    
                       D_Diff_neg(j,i,v) = 0;
                  
           end
           
           if  D_Diff(j,i,v)<0 && D_Diff(j,i,v)> -cuttoff
                       
                       D_Diff_pos(j,i,v) = abs(D_Diff(j,i,v));
                       
                   elseif D_Diff(j,i,v)< -cuttoff
                       
                       D_Diff_pos(j,i,v) = cuttoff;
                                     
                   else
                       D_Diff_neg(j,i,v) = 0;
           end    
                   
           
              
          end
                 
                 end
  end
end  

end
                    


   
end
      