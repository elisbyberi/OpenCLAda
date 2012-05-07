--------------------------------------------------------------------------------
--  Copyright (c) 2011, Felix Krause
--  All rights reserved.
--
--  Redistribution and use in source and binary forms, with or without
--  modification, are permitted provided that the following conditions are met:
--
--  * Redistributions of source code must retain the above copyright notice,
--    this list of conditions and the following disclaimer.
--  * Redistributions in binary form must reproduce the above copyright notice,
--    this list of conditions and the following disclaimer in the documentation
--    and/or other materials provided with the distribution.
--
--  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
--  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
--  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
--  ARE DISCLAIMED.
--  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
--  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
--  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--  (INCLUDING NEGLIGENCE OR OTHERWISE)  ARISING IN ANY WAY OUT OF THE USE OF
--  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------

with CL.Command_Queues;
with CL.Events;
with CL.Kernels;

private with CL.Helpers;

package CL.Queueing is
   subtype Kernel_Dimension is UInt range 1 .. 3;

   type Map_Flags is record
      Read  : Boolean;
      Write : Boolean;
   end record;

   function Execute_Kernel (Queue            : Command_Queues.Command_Queue'Class;
                            Kernel           : Kernels.Kernel'Class;
                            Dimension        : Kernel_Dimension;
                            Global_Work_Size : access constant Size_List;
                            Local_Work_Size  : access constant Size_List;
                            Wait_For         : access Events.Event_List)
                            return Events.Event;

   function Execute_Task (Queue    : Command_Queues.Command_Queue'Class;
                          Kernel   : Kernels.Kernel'Class;
                          Wait_For : access Events.Event_List)
                          return Events.Event;

   function Marker (Queue : Command_Queues.Command_Queue'Class)
                    return Events.Event;

   procedure Wait_For_Events (Queue      : Command_Queues.Command_Queue'Class;
                              Event_List : Events.Event_List);

   procedure Barrier (Queue : Command_Queues.Command_Queue'Class);

private
   for Map_Flags use record
      Read  at 0 range 0 .. 0;
      Write at 0 range 1 .. 1;
   end record;
   pragma Warnings (Off);
   for Map_Flags'Size use Bitfield'Size;
   pragma Warnings (On);
   pragma Convention (C_Pass_By_Copy, Map_Flags);

   function Raw_Event_List is new Helpers.Raw_List_From_Polymorphic
     (Element_T => Events.Event, Element_List_T => Events.Event_List);
end CL.Queueing;
