(**************************************************************************)
(*                                                                        *)
(*                              OCamlPro TypeRex                          *)
(*                                                                        *)
(*   Copyright OCamlPro 2011-2016. All rights reserved.                   *)
(*   This file is distributed under the terms of the LGPL v2.1 with       *)
(*   the special exception on linking described in the file LICENSE.      *)
(*      (GNU Lesser General Public Licence version 2.1)                   *)
(*                                                                        *)
(*     Contact: <typerex@ocamlpro.com> (http://www.ocamlpro.com/)         *)
(*                                                                        *)
(*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       *)
(*  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES       *)
(*  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND              *)
(*  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS   *)
(*  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN    *)
(*  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN     *)
(*  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE      *)
(*  SOFTWARE.                                                             *)
(**************************************************************************)

(* [subst f src] will substitute any variable in [src] by the result
   of calling [f] with that variable as argument.
   The following variable patterns are recognized:
    $(...)
    ${...}
    %{...}
    %{...}%
   Within such a pattern, the variable can be any arbitrary sequence
   of characters, excepting the terminator of the pattern. Substitution is
   done recursively, i.e. it is possible to nest variables, as in
   "foo_${bar_${type}$(xx)}".
   The backslash character ('\\') can be used to escape any character, in
   particular the ones used for patterns.

   Optional arguments [~dollarparen], [~percentbrace] and [~percentbracesym]
   can be used to specify different substitution functions for $(...),
   %{...} and %{...}%. If absent, they default to the provided [f] function,
   that is always used for ${...} .
*)


val subst : (string -> string) ->
  ?dollarparen:(string -> string) ->
  ?percentbrace:(string -> string) ->
  ?percentbracesym:(string -> string) ->
  string ->
  string

(* Error handling for [subst]. [subst] should only raise the following
   exception [Error error]. *)
type delim =
  | DollarParen      (* $(XXX)  *)
  | DollarBrace      (* ${XXX}  *)
  | PercentBrace     (* %{XXX}  *)
  | PercentBraceSym  (* %{XXX}% *)

type error =
  | UnexpectedEndOfString
  | SubstitutionError of string * delim * exn

exception Error of error

val string_of_error : error -> string










module Gen : sig
  (* This module implements a simple algorithm for substituting any
     string in any string. If several strings can be substituted at the
     same place, the one starting at the earliest position is chosen,
     and among different strings at the same position, the longest match
     is chosen.

     The current worst complexity is O(N.M) where N is the length of the
     argument string and M is the longest string that can be
     substituted. We should probably implement KMP at some point for
     applications where performance matters.
  *)

  type subst

  val empty_subst : unit -> subst

  (* [add_to_subst subst src dst] mutates [subst] to add
     a transition from [src] to [dst]. *)
  val add_to_subst : subst -> string -> string -> unit
  (* [add_to_copy subst src dst] returns a copy of [subst] with a
     transition from [src] to [dst]. *)
  val add_to_copy : subst -> string -> string -> subst

  val subst_of_list : (string * string) list -> subst

  val subst : subst -> string -> int * string
  val iter_subst : subst -> string -> int * string
end

module M : sig

  type 'a subst

  val empty_subst : unit -> 'a subst

(* [add_to_subst subst src dst] mutates [subst] to add
 a transition from [src] to [dst]. *)
  val add_to_subst : 'a subst -> string -> ('a -> string) -> unit

(* [add_to_copy subst src dst] returns a copy of [subst] with a
   transition from [src] to [dst]. *)
  val add_to_copy : 'a subst -> string -> ('a -> string) -> 'a subst


  val subst_of_list : (string * ('a -> string)) list -> 'a subst
  val subst : 'a subst -> string -> 'a -> int * string
  val iter_subst : 'a subst -> string -> 'a -> int * string

end

module Static : sig
  type t
  val create : string array -> t
  val subst : t -> string array -> string -> int * string
  val iter_subst : t -> string array -> string -> string

end


(*
module New : sig

  type 'a t
  type counter = int ref

  val empty_subst : unit -> 'a t

  (* [add_to_subst t src dst] mutates [subst] to add
     a transition from [src] to [dst]. *)
  val add_to_subst : 'a t -> string -> ('a -> string) -> unit

  (* [add_to_copy t src dst] returns a partial copy of [subst]
     with a transition from [src] to [dst]. [subst] is not modified,
     but calls to [add_to_subst] on any of the two titutions might
     change the other one. *)
  val add_to_copy : 'a t -> string -> ('a -> string) -> 'a t

  val subst_of_list : (string * ('a -> string)) list -> 'a t
  val subst : ?counter:counter -> 'a t -> string -> 'a -> string
  val iter_subst : ?counter:counter -> 'a t -> string -> 'a -> string

  val create_static : string array -> string array t
  val subst_static : ?counter:counter -> string array t -> string array ->
    string -> string
  val iter_static : ?counter:counter -> string array t -> string array ->
    string -> string

  val iter_with_list : ?counter:counter -> string -> (string * string) list -> string
  val iter_with_array : ?counter:counter -> string -> (string * string) array -> string

  end
*)
