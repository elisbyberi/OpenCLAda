--------------------------------------------------------------------------------
-- Copyright (c) 2013, Felix Krause <contact@flyx.org>
--
-- Permission to use, copy, modify, and/or distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
-- ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
-- ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
-- OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
--------------------------------------------------------------------------------

with CL.API;
with CL.Enumerations;
with CL.Helpers;

package body CL.Contexts is

   -----------------------------------------------------------------------------
   --  Helpers
   -----------------------------------------------------------------------------

   procedure Callback_Dispatcher (Error_Info   : Interfaces.C.Strings.chars_ptr;
                                  Private_Info : C_Chars.Pointer;
                                  CB           : IFC.ptrdiff_t;
                                  User_Data    : Error_Callback) is
   begin
      User_Data (Interfaces.C.Strings.Value    (Error_Info),
                 C_Chars.Value (Private_Info, CB));
   end Callback_Dispatcher;

   function UInt_Info is
     new Helpers.Get_Parameter (Return_T    => UInt,
                                Parameter_T => Enumerations.Context_Info,
                                C_Getter    => API.Get_Context_Info);

   -----------------------------------------------------------------------------
   --  Implementations
   -----------------------------------------------------------------------------

   package body Constructors is

      function Create_For_Devices (Platform : Platforms.Platform'Class;
                                   Devices  : Platforms.Device_List;
                                   Callback : Error_Callback := null)
                                   return Context is
         Error       : aliased Enumerations.Error_Code;
         Ret_Context : System.Address;
         Props       : Address_List := (Value (Platform_Identifier),
                                        CL_Object (Platform).Location,
                                        System.Null_Address);
         function Raw_Device_List is
           new Helpers.Raw_List (Element_T => Platforms.Device,
                                 Element_List_T => Platforms.Device_List);
         Raw_List : Address_List := Raw_Device_List (Devices);

         function Address is new
           Ada.Unchecked_Conversion (Source => Error_Callback,
                                     Target => System.Address);
      begin
         if Callback /= null then
            Ret_Context := API.Create_Context (Props (1)'Unchecked_Access,
                                               Devices'Length,
                                               Raw_List (1)'Address,
                                               Callback_Dispatcher'Access,
                                               Address (Callback),
                                               Error'Unchecked_Access);
         else
            Ret_Context := API.Create_Context (Props (1)'Unchecked_Access,
                                               Devices'Length,
                                               Raw_List (1)'Address,
                                               null, System.Null_Address,
                                               Error'Unchecked_Access);
         end if;

         Helpers.Error_Handler (Error);

         return Context'(Ada.Finalization.Controlled with Location => Ret_Context);
      end Create_For_Devices;

      function Create_From_Type (Platform : Platforms.Platform'Class;
                                 Dev_Type : Platforms.Device_Kind;
                                 Callback : Error_Callback := null)
                                 return Context is
         Error       : aliased Enumerations.Error_Code;
         Ret_Context : System.Address;
         Props       : Address_List := (Value (Platform_Identifier),
                                        CL_Object (Platform).Location,
                                        System.Null_Address);
         function To_Address is new
           Ada.Unchecked_Conversion (Source => Error_Callback,
                                     Target => System.Address);

         function To_Bitfield is new
           Ada.Unchecked_Conversion (Source => Platforms.Device_Kind,
                                     Target => Bitfield);
      begin
         if Callback /= null then
            Ret_Context :=
              API.Create_Context_From_Type (Props (1)'Unchecked_Access,
                                            To_Bitfield (Dev_Type),
                                            Callback_Dispatcher'Access,
                                            To_Address (Callback),
                                            Error'Unchecked_Access);
         else
            Ret_Context :=
              API.Create_Context_From_Type (Props (1)'Unchecked_Access,
                                            To_Bitfield (Dev_Type), null,
                                            System.Null_Address,
                                            Error'Unchecked_Access);
         end if;

         Helpers.Error_Handler (Error);

         return Context'(Ada.Finalization.Controlled with Location => Ret_Context);
      end Create_From_Type;
   end Constructors;

   overriding procedure Adjust (Object : in out Context) is
      use type System.Address;
   begin
      if Object.Location /= System.Null_Address then
         Helpers.Error_Handler (API.Retain_Context (Object.Location));
      end if;
   end Adjust;

   overriding procedure Finalize (Object : in out Context) is
      use type System.Address;
   begin
      if Object.Location /= System.Null_Address then
         Helpers.Error_Handler (API.Release_Context (Object.Location));
      end if;
   end Finalize;

   function Reference_Count (Source : Context) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Reference_Count);
   end Reference_Count;

   function Devices (Source : Context) return Platforms.Device_List is
      function Getter is
        new Helpers.Get_Parameters (Return_Element_T => System.Address,
                                    Return_T         => Address_List,
                                    Parameter_T      => Enumerations.Context_Info,
                                    C_Getter         => API.Get_Context_Info);
      Raw_List : constant Address_List := Getter (Source, Enumerations.Devices);
      Ret_List : Platforms.Device_List (Raw_List'Range);
   begin
      for Index in Raw_List'Range loop
         Ret_List (Index) := Platforms.Device'(Ada.Finalization.Controlled with
                                               Location => Raw_List (Index));
      end loop;
      return Ret_List;
   end Devices;

   function Platform (Source : Context) return Platforms.Platform is
      function Properties_Info is
        new Helpers.Get_Parameters (Return_Element_T => System.Address,
                                     Return_T         => Address_List,
                                     Parameter_T      => Enumerations.Context_Info,
                                     C_Getter         => API.Get_Context_Info);
      Props : constant Address_List
        := Properties_Info (Source, Enumerations.Properties);
      Index : Positive     := Props'First;

      use type System.Address;
   begin
      while (Index < Props'Last) loop
         if Props (Index) = Value (Platform_Identifier) then
            return Platforms.Platform'(Ada.Finalization.Controlled with
                                       Location => Props (Index + 1));
         end if;
         Index := Index + 2;
      end loop;

      raise Internal_Error;
   end Platform;
end CL.Contexts;
