with Ada.Text_IO;
with System;

with CL.Platforms;
with CL.Contexts;
with CL.Memory.Buffers;
with CL.Command_Queues;
with CL.Programs;
with CL.Kernels;
with CL.Queueing;
with CL.Queueing.Memory_Objects;
with CL.Events;
with CL.Vectors;

with CL_Test.Helpers;

procedure CL_Test.Vector_Passing is
   package IO renames Ada.Text_IO;
   use CL.Vectors;

   Destination_List : aliased Int2_Array := New_Array ((1 => (0, 0)));

   function Int2_Buffer is
     new CL.Memory.Buffers.Constructors.Create_From_Source
       (Element => CL.Vectors.Int2, Element_List => Int2_Array);

   package Int2_Objects is
     new CL.Queueing.Memory_Objects (Element      => CL.Vectors.Int2,
                                     Element_List => Int2_Array);

   Platform    : CL.Platforms.Platform;
   Device      : CL.Platforms.Device;
   Device_List : CL.Platforms.Device_List (1 .. 1);
   Context     : CL.Contexts.Context;
   Source1, Source2, Destination : CL.Memory.Buffers.Buffer;
   Program     : CL.Programs.Program;
   Kernel      : CL.Kernels.Kernel;
   Queue       : CL.Command_Queues.Command_Queue;
   Event       : CL.Events.Event;

   Kernel_File : IO.File_Type;

   use type CL.Size;
   
   procedure Set_Input is new CL.Kernels.Set_Kernel_Argument (Argument_Type => Int2, Argument_Index => 0);
begin

   Platform    := CL.Platforms.List (1);
   Device      := Platform.Devices (CL.Platforms.Device_Kind'(GPU => True,
                                                              others => False)) (1);
   Device_List := (1 => Device);
   Context     := CL.Contexts.Constructors.Create_For_Devices (Platform, Device_List);
   Destination := CL.Memory.Buffers.Constructors.Create (Context, CL.Memory.Write_Only, CL.Vectors.Int2'Size / System.Storage_Unit);
   Queue       := CL.Command_Queues.Constructors.Create (Context, Device,
                                                         CL.Platforms.CQ_Property_Vector'(others => False));

   IO.Open (Kernel_File, IO.In_File, "../tests/vector_passing.cl");
   declare
      Kernel_Source : String := CL_Test.Helpers.Read_File (Kernel_File);
   begin
      IO.Close (Kernel_File);
      Program := CL.Programs.Constructors.Create_From_Source
        (Context, Kernel_Source);
   end;
   Program.Build (Device_List, "", null);
   Kernel := CL.Kernels.Constructors.Create (Program, "add");
   Set_Input (Kernel, CL_Vector (7, 42));
   Kernel.Set_Kernel_Argument_Object (1, Destination);
   Event := CL.Queueing.Execute_Task (Queue, Kernel, null);
   Event.Wait_For;
   Int2_Objects.Read_Buffer (Queue, Destination, True, 0, Destination_List, Event);
   IO.Put ("Output: (");
   for Index in Destination_List'Range loop
      IO.Put ("(" & Destination_List (Index).S (0)'Img & "," & Destination_List (Index).S (1)'Img & "),");
   end loop;
   IO.Put_Line (")");

end CL_Test.Vector_Passing;