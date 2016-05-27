(**************************************************************************)
(*                                                                        *)
(*                              OCamlPro TypeRex                          *)
(*                                                                        *)
(*   Copyright OCamlPro 2011-2016. All rights reserved.                   *)
(*   This file is distributed under the terms of the GPL v3.0             *)
(*      (GNU Public Licence version 3.0).                                 *)
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

(* Currently, we have no distinction between implicit and .-relative
   filenames. We should probably do that.
*)


open StringCompat


(* IMPORTANT OS specificities (from the JDK):

   Each filename is composed of:
   - an optional prefix:
   nothing
   / root on Unix for absolute filenames
   \ root on Windows for absolute filenames without drive
   \\ UNC filename
   c: drive on Windows for relative filenames
   c:\ root and drive on windows for absolute filenames
   (nothing on Unix or c: or C: on Windows or \)
   - a list of basenames (possibly empty for the root )

   - there is an official separator like \ or /
   - there is an official path-separator like : (unix) or ; (windows)

   - listRoots() returns the list of available drives
   - getAbsolutePath() -> absolute path
   - getCanonicalPath() -> absolute path simplified and without symlinks

*)


  type t = {
    file_basename : string;
    file_dir : t;
    file_string : string;
    (* The system filename, i.e. with system-specific separators *)
    file_partition : string;
  }


  let basename t = t.file_basename


  let rec is_absolute t =
    if t.file_dir != t then
      is_absolute t.file_dir
    else
      t.file_basename = ""

  let is_relative t = not (is_absolute t)


  let to_string t = t.file_string

  let dirname t =
    if t.file_dir == t then
      match t.file_basename with
        "" | "." -> t
      | _ ->
        let rec root = {
          file_dir = root;
          file_basename = ".";
          file_partition = t.file_partition;
          file_string = ".";
        } in
        root
    else t.file_dir






let add_basename_string dir basename =
  if dir.file_string = FileOS.dir_separator_string then
    FileOS.dir_separator_string ^ basename
  else
    dir.file_string ^ FileOS.dir_separator_string ^ basename

let add_basename dir basename =
  if dir.file_basename = "." then
    let rec base_dir = {
      file_basename =  basename;
      file_dir = base_dir;
      file_partition = dir.file_partition;
      file_string = basename;
    } in
    base_dir
  else
    if basename = ".." && (dir.file_basename <> "..") then dir.file_dir else
      {
        file_basename =  basename;
        file_dir = dir;
        file_partition = dir.file_partition;
        file_string = add_basename_string dir basename;
      }

let rec add_basenames dir list =
  match list with
    [] -> dir
  | "" :: tail ->
    add_basenames dir tail
  | basename :: tail ->
    add_basenames (add_basename dir basename) tail


let concat t1 t2 =
  if t2.file_partition <> "" && t1.file_partition <> t2.file_partition then
    failwith "Filename2.concat: filenames have different partitions";
  if is_absolute t2 then
    failwith "Filename2.concat: second filename is absolute";

  let rec iter dir t =
    let dir =
      if t.file_dir != t then
        iter dir t.file_dir
      else dir in
    add_basename dir t.file_basename
  in
  iter t1 t2





let check_suffix file suffix =
  Filename.check_suffix file.file_basename suffix

let add_suffix t suffix =
  match t.file_basename with
    "." | ".." | "" -> failwith "Filename2.add_extension: symbolic file"
  | _ ->
    if t.file_dir == t then
      let rec root = {
        file_basename = t.file_basename ^ suffix;
        file_partition = t.file_partition;
        file_dir = root;
        file_string = t.file_string ^ suffix;
      }
      in
      root
    else
      {
        file_basename = t.file_basename ^ suffix;
        file_partition = t.file_partition;
        file_dir = t.file_dir;
        file_string = t.file_string ^ suffix;
      }


(* utilities for [of_string] *)

let rec normalize_path path =
  match path with
    [] -> []
  | dir :: tail ->
    let dir = dir :: normalize_path tail in
    match dir with
    | "" :: path -> path
    | "." :: path -> path
    | ".." :: _ -> dir
    | _ :: ".." :: path -> path
    | _ -> dir

let rec remove_leading_dotdots path =
  match path with
    ".." :: path -> remove_leading_dotdots path
  | _ -> path

let rec make dir path =
  match path with
    [] -> dir
  | basename :: tail ->
    let t = {
      file_basename = basename;
      file_dir = dir;
      file_partition =  dir.file_partition;
      file_string = add_basename_string dir basename;
    } in
    make t tail

let of_path part path =
  let absolute = match path with
      "" :: _ :: _ -> true
    | _ -> false
  in
  let path = normalize_path path in
  let path = if absolute then remove_leading_dotdots path else path in

  if absolute then
    let rec root = {
      file_basename = "";
      file_dir = root;
      file_string = part ^ FileOS.dir_separator_string;
      file_partition = part;
    } in
    make root path
  else
    match path with
      [] ->
        let rec current_dir = {
          file_basename = ".";
          file_dir = current_dir;
          file_string = part ^ ".";
          file_partition = part;
        } in
        current_dir
    | dir :: tail ->
      let rec base_dir = {
        file_basename = dir;
        file_dir = base_dir;
        file_partition = part;
        file_string = part ^ dir;
      } in
      make base_dir tail

let of_unix_string s =
  let path = OcpString.split s '/' in
  let part = "" in
  of_path part path


let of_win32_string s =
  let s1, s2  = OcpString.cut_at s ':' in
  let ss = if s1 == s then s else s2 in
  let part = if s1 == s then "" else (String.lowercase s1) ^ ":" in
  let path = OcpString.split ss '\\' in
  of_path part path

let of_string s =
  if FileOS.win32 then of_win32_string s else of_unix_string s




let read_sublines file off len =
  FileString.read_sublines (to_string file) off len
let iteri_lines f file = FileString.iteri_lines f (to_string file)
let iter_lines f file = FileString.iter_lines f (to_string file)
let write_file file s = FileString.write_file (to_string file) s
let read_file file = FileString.read_file (to_string file)
let write_lines file lines = FileString.file_of_lines (to_string file) lines
let read_lines file = FileString.lines_of_file (to_string file)

let read_subfile file pos len =
  FileString.read_subfile (to_string file) pos len
let string_of_subfile = read_subfile

let file_of_lines = write_lines
let lines_of_file = read_lines

let string_of_file = read_file
let file_of_string = write_file

let rename t1 t2 = Sys.rename (to_string t1) (to_string t2)

let exists file = Sys.file_exists (to_string file)
let is_directory filename =
  try let s = MinUnix.stat (to_string filename) in
    s.MinUnix.st_kind = MinUnix.S_DIR with _ -> false

let is_link file = FileString.is_link (to_string file)
let size file = FileString.size (to_string file)

let stat filename = MinUnix.stat (to_string filename)
let lstat filename = MinUnix.lstat (to_string filename)

  (*
    let size64 filename =
    let s = MinUnix.LargeFile.stat (to_string filename) in
    s.MinUnix.LargeFile.st_size
  *)

let getcwd () = of_string (Sys.getcwd ())

let open_in filename = open_in (to_string filename)
let open_out filename = open_out (to_string filename)

let open_in_bin filename = open_in_bin (to_string filename)
let open_out_bin filename = open_out_bin (to_string filename)


let copy_file f1 f2 =
  FileString.copy_file (to_string f1) (to_string f2)

let open_fd file mode perm = MinUnix.openfile (to_string file) mode perm

let remove file = Sys.remove (to_string file)

let iter_blocks f file =
  FileString.iter_blocks f (to_string file)

let safe_mkdir ?mode dir = FileString.safe_mkdir ?mode (to_string dir)
let copy_rec src dst = FileString.copy_rec (to_string src) (to_string dst)
let uncopy_rec src dst = FileString.uncopy_rec (to_string src) (to_string dst)


let extensions file = FileString.extensions_of_basename file.file_basename

let last_extension file =
  FileString.last_extension (extensions file)

let chop_extension f =
  let (basename, ext) = OcpString.cut_at f.file_basename '.' in
  let ext_len = String.length f.file_basename - String.length basename in
  if ext_len = 0 then f else
    let len = String.length f.file_string in
    { f with
      file_basename = basename;
      file_string = String.sub f.file_string 0 (len-ext_len);
    }

let equal t1 t2 =
  t1.file_string = t2.file_string &&
  t1.file_partition = t2.file_partition


let temp_file t ext =
  of_string (Filename.temp_file (to_string t) ext)

let current_dir_name = of_string "."
let getcwd () = of_string (Sys.getcwd ())

let to_rooted_string t =
  if is_absolute t then
    t.file_string
  else
    Printf.sprintf ".%c%s" FileOS.dir_separator t.file_string

module String = FileString
module Lines = FileLines
module Channel = FileChannel
module OS = FileOS

(*
let safe_basename s =
  basename (of_string s)
*)

module Op = struct

  let (//) = add_basename

end



let () =
  let root_dir = of_unix_string "/" in
  let current_dir = of_unix_string "." in
  let parent_dir = of_unix_string ".." in
  let relative_dir = add_basename current_dir "foo" in
  let absolute_dir = add_basename root_dir "foo" in
  let empty_dir = of_unix_string "" in
  let implicit_dir = of_unix_string "foo" in


  assert (to_string root_dir = "/");
  assert (to_string current_dir = ".");
  assert (to_string parent_dir = "..");
  assert (to_string relative_dir = "foo");
  assert (to_string absolute_dir = "/foo");
  assert (to_string empty_dir = ".");
  assert (to_string implicit_dir = "foo");

  assert (is_absolute root_dir);
  assert (not (is_absolute current_dir));
  assert (not (is_absolute parent_dir));
  assert (not (is_absolute relative_dir));
  assert (is_absolute absolute_dir);
  assert (not (is_absolute empty_dir));
  assert (not (is_absolute implicit_dir));

  assert (not (is_relative root_dir));
  assert (is_relative current_dir);
  assert (is_relative parent_dir);
  assert (is_relative relative_dir);
  assert (not (is_relative absolute_dir));
  assert (is_relative empty_dir); (* different from Filename.is_relative "" *)
  assert (is_relative implicit_dir);

  ()