with Ada.Strings.Fixed;

package body CL.Vector_Operations is
   
   function Element_Wise (Left, Right : Vector) return Vector is
      Result : Vector;
   begin
      for I in Natural (Vector_Range'First) .. Natural (Vector_Range'Last) loop
         Result (I) := Operation (Left (I), Right (I));
      end loop;
      return Result;
   end Element_Wise;
   
   function Apply_Scalar (Left : Vector; Right : Base) return Vector is
      Result : Vector;
   begin
      for I in Natural (Vector_Range'First) .. Natural (Vector_Range'Last) loop
         Result (I) := Operation (Left (I), Right);
      end loop;
      return Result;
   end Apply_Scalar;
   
   function Add is new Element_Wise (Operation => "+");
   function "+" (Left, Right: Vector) return Vector renames Add;
   
   function Substract is new Element_Wise (Operation => "-"); 
   function "-" (Left, Right: Vector) return Vector renames Substract;
   
   function Multiply_Scalar is new Apply_Scalar (Operation => "*"); 
   function "*" (Left : Vector; Right : Base) return Vector
      renames Multiply_Scalar;
   
   --  Element-wise multiplication
   function Multiply is new Element_Wise (Operation => "*"); 
   function "*" (Left, Right : Vector) return Vector renames Multiply;
   
   function Divide_Scalar is new Apply_Scalar (Operation => "/"); 
   function "/" (Left : Vector; Right : Base) return Vector renames Divide_Scalar;
   
   --  Element-wise division
   function Divide is new Element_Wise (Operation => "/"); 
   function "/" (Left, Right : Vector) return Vector renames Divide;
   
   function To_String (Value : Vector) return String is
      use Ada.Strings.Fixed;
      
      Max : constant := 256;
      
      Result : String (1 .. Max);
      Pos    : Integer := 2;
   begin
      Result (1) := '(';
      Pos := 2;
      for I in Natural (Vector_Range'First) .. Natural (Vector_Range'Last) loop
         if Pos /= 2 and Pos + 1 <= Max then
            Result (Pos .. Pos + 1) := ", ";
            Pos := Pos + 2;
         end if;
         declare
            Repr : String := To_String (Value (I));
         begin
            if Pos + Repr'Length - 1 <= Max then
               Result (Pos .. Pos + Repr'Length - 1) := Repr;
               Pos := Pos + Repr'Length;
            end if;
         end;
      end loop;
      if Pos <= Max then
         Result (Pos) := ')';
         Pos := Pos + 1;
      end if;
      return Result (1 .. Pos - 1);
   end To_String;

end CL.Vector_Operations;
