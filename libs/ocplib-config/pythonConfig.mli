(**************************************************************************)
(*                                                                        *)
(*   Typerex Libraries                                                    *)
(*                                                                        *)
(*   Copyright 2011-2017 OCamlPro SAS                                     *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

(* Python option file :

[section]
option = value
option : value
option = long
  value
; comment
# other comment

*)

open StringCompat

type t

exception DuplicateSectionError of t * string
exception BadSectionLine of string
exception BadOptionLine of string
exception SectionNotFound of string

val create : unit -> t

val defaults : t -> string StringMap.t
val sections : t -> string list (* all sections, exception DEFAULT *)
val add_new_section : t -> string -> unit
val add_section : t -> string -> unit
val has_section : t -> string -> bool
val options : t -> string -> string StringMap.t
val has_option : t -> string -> string -> bool
val add_option : t -> string -> string -> string -> unit

val get : t -> string -> string -> string
val get_int : t -> string -> string -> int
val get_float : t -> string -> string -> float
val get_bool : t -> string -> string -> bool
val items : t -> string -> (string * string) list
val set : t -> string -> string -> string -> unit
val set_int : t -> string -> string -> int -> unit
val set_float : t -> string -> string -> float -> unit
val set_bool : t -> string -> string -> bool -> unit
val remove_option : t -> string -> string -> unit
val remove_section : t -> string -> unit

(* TODO: Python does some interpolation, i.e. %x is replaced by the value
of option "x" at that point. *)

val write : File.t -> t -> unit
val read : File.t -> t
