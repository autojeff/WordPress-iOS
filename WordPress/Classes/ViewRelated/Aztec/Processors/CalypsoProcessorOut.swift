import Foundation
import Aztec


// MARK: - CalypsoProcessorIn
//
class CalypsoProcessorOut: Processor {

    /// Converts the standard-HTML output of Aztec into the hybrid-HTML that WordPress uses to store
    /// posts.
    ///
    /// This method was a direct migration from:
    /// https://github.com/Automattic/wp-calypso/blob/38040768fba5ee8539ebd69204a817f644aa15f3/client/lib/formatting/index.js#L184
    ///
    func process(_ text: String) -> String {

//     if ( ! html ) {
        guard text.characters.count > 0 else {
//         return '';
            return ""
        }

        let lineBreakMarker = "<wp-line-break>"
        let preserveMarker = "<wp-preserve>"

//     let preserve_linebreaks = false,
        var preserveLinebreaks = false
//         preserve_br = false;
        var preserveBr = false

// FIX FIX: Still Needed?
//        var preserve = [String]()

//     const blocklist = 'blockquote|ul|ol|li|table|thead|tbody|tfoot|tr|th|td|h[1-6]|fieldset';
        let blocklist = "blockquote|ul|ol|li|dl|dt|dd|table|thead|tbody|tfoot|tr|th|td|h[1-6]|fieldset|figure"
//     const blocklist1 = blocklist + '|div|p';
        let blocklist1 = blocklist + "|div|p"
//     const blocklist2 = blocklist + '|pre';
        let blocklist2 = blocklist + "|pre"

        var output = text

        output = output.replacingMatches(of: "<p>(?:<br ?\\/?>|\\u00a0|\\uFEFF| )*<\\/p>", with: "<p>&nbsp;</p>")





        // FIX FIX: Calypso lacks <style processing
//        // Protect script and style tags.
//        if output.contains("<script") || output.contains("<style") {
//            output = output.replacingMatches(of: "<(script|style)[^>]*>[\\s\\S]*?<\\/\\1>", using: { (match, _) -> String in
//                preserve.append(match)
//
//                return preserveMarker
//            })
//        }

        // Protect pre|script tags
//     if ( html.indexOf( '<pre' ) !== -1 || html.indexOf( '<script' ) !== -1 ) {
        if output.contains("<pre") || output.contains("<script") {
//         preserve_linebreaks = true;
            preserveLinebreaks = true

//         html = html.replace( /<(pre|script)[^>]*>[\s\S]+?<\/\1>/g, function( a ) {
            output = output.replacingMatches(of: "<(pre|script)[^>]*>[\\s\\S]+?<\\/\\1>", using: { (match, _) -> String in
//             a = a.replace( /<br ?\/?>(\r\n|\n)?/g, '<wp-line-break>' );
                var string = match.replacingMatches(of: "<br ?\\/?>(\r\n|\n)?", with: lineBreakMarker)
//             a = a.replace( /<\/?p( [^>]*)?>(\r\n|\n)?/g, '<wp-line-break>' );
                string = string.replacingMatches(of: "<\\/?p( [^>]*)?>(\r\n|\n)?", with: lineBreakMarker)
//             return a.replace( /\r?\n/g, '<wp-line-break>' );
                return string.replacingMatches(of: "\r?\n", with: lineBreakMarker)
            })
        }


        // Remove line breaks but keep <br> tags inside image captions.
//     if ( html.indexOf( '[caption' ) !== -1 ) {
        if output.contains("[caption") {
//         preserve_br = true;
            preserveBr = true

//         html = html.replace( /\[caption[\s\S]+?\[\/caption\]/g, function( a ) {
            output = output.replacingMatches(of: "\\[caption[\\s\\S]+?\\[\\/caption\\]", using: { (match, _) -> String in
//             return a.replace( /<br([^>]*)>/g, '<wp-temp-br$1>' ).replace( /[\r\n\t]+/, '' );
                let string = match.replacingMatches(of: "<br([^>]*)>", with: "<wp-temp-br$1>")
                return string.replacingMatches(of: "[\r\n\t]+", with: "")
            })
        }

        // Normalize white space characters before and after block tags.
//     html = html.replace( new RegExp( '\\s*</(' + blocklist1 + ')>\\s*', 'g' ), '</$1>\n' );
        output = output.replacingMatches(of: "\\s*</(\(blocklist1))>\\s*", with: "</$1>\n")
//     html = html.replace( new RegExp( '\\s*<((?:' + blocklist1 + ')(?: [^>]*)?)>', 'g' ), '\n<$1>' );
        output = output.replacingMatches(of: "\\s*<((?:" + blocklist1 + ")(?: [^>]*)?)>", with: "\n<$1>")

        // Mark </p> if it has any attributes.
//     html = html.replace( /(<p [^>]+>.*?)<\/p>/g, '$1</p#>' );
        output = output.replacingMatches(of: "(<p [^>]+>.*?)<\\/p>", with: "$1</p#>")

        // Preserve the first <p> inside a <div>.
//     html = html.replace( /<div( [^>]*)?>\s*<p>/gi, '<div$1>\n\n' );
        output = output.replacingMatches(of: "<div( [^>]*)?>\\s*<p>", with: "<div$1>\n\n", options: .caseInsensitive)

        // Remove paragraph tags.
        //     html = html.replace( /\s*<p>/gi, '' );
        output = output.replacingMatches(of: "\\s*<p>", with: "", options: .caseInsensitive)
        //     html = html.replace( /\s*<\/p>\s*/gi, '\n\n' );
        output = output.replacingMatches(of: "\\s*<\\/p>\\s*", with: "\n\n", options: .caseInsensitive)

        // Normalize white space chars and remove multiple line breaks.
//     html = html.replace( /\n[\s\u00a0]+\n/g, '\n\n' );
        output = output.replacingMatches(of: "\n[\\s\\u00a0]+\n", with: "\n\n")

        // Replace <br> tags with line breaks.
//     html = html.replace( /\s*<br ?\/?>\s*/gi, '\n' );
        output = output.replacingMatches(of: "(\\s*)<br ?\\/?>\\s*", options: .caseInsensitive, using: { (match, ranges) -> String in
            if ranges.count > 0 && ranges[0].contains("\n") {
                return "\n\n"
            }

            return "\n"
        })

        // Fix line breaks around <div>.
//     html = html.replace( /\s*<div/g, '\n<div' );
        output = output.replacingMatches(of: "\\s*<div", with: "\n<div")
//     html = html.replace( /<\/div>\s*/g, '</div>\n' );
        output = output.replacingMatches(of: "<\\/div>\\s*", with: "</div>\n")

        // Fix line breaks around caption shortcodes.
//     html = html.replace( /\s*\[caption([^\[]+)\[\/caption\]\s*/gi, '\n\n[caption$1[/caption]\n\n' );
        output = output.replacingMatches(of: "\\s*\\[caption([^\\[]+)\\[\\/caption\\]\\s*", with: "\n\n[caption$1[/caption]\n\n")
//     html = html.replace( /caption\]\n\n+\[caption/g, 'caption]\n\n[caption' );
        output = output.replacingMatches(of: "caption\\]\n\n+\\[caption", with: "caption]\n\n[caption")

        // Pad block elements tags with a line break.
//         new RegExp( '\\s*<((?:' + blocklist2 + ')(?: [^>]*)?)\\s*>', 'g' ),
        output = output.replacingMatches(of: "\\s*<((?:" + blocklist2 + ")(?: [^>]*)?)\\s*>", with: "\n<$1>")
//     html = html.replace( new RegExp( '\\s*</(' + blocklist2 + ')>\\s*', 'g' ), '</$1>\n' );
        output = output.replacingMatches(of: "\\s*</(" + blocklist2 + ")>\\s*", with: "</$1>\n")

        // Indent <li>, <dt> and <dd> tags.
//     html = html.replace( /<li([^>]*)>/g, '\t<li$1>' );
        output = output.replacingMatches(of: "<((li|dt|dd)[^>]*)>", with: " \t<$1>")

        // Fix line breaks around <select> and <option>.
//     if ( html.indexOf( '<option' ) !== -1 ) {
        if output.contains("<option") {
//         html = html.replace( /\s*<option/g, '\n<option' );
            output = output.replacingMatches(of: "\\s*<option", with: "\n<option")
//         html = html.replace( /\s*<\/select>/g, '\n</select>' );
            output = output.replacingMatches(of: "\\s*<\\/select>", with: "\n</select>")
        }

        // Pad <hr> with two line breaks.
//     if ( html.indexOf( '<hr' ) !== -1 ) {
        if output.contains("<hr") {
//         html = html.replace( /\s*<hr( [^>]*)?>\s*/g, '\n\n<hr$1>\n\n' );
            output = output.replacingMatches(of: "\\s*<hr( [^>]*)?>\\s*", with: "\n\n<hr$1>\n\n")
        }

        // Remove line breaks in <object> tags.
//     if ( html.indexOf( '<object' ) !== -1 ) {
        if output.contains("<object") {
//         html = html.replace( /<object[\s\S]+?<\/object>/g, function( a ) {
            output = output.replacingMatches(of: "<object[\\s\\S]+?<\\/object>", using: { (match, _) -> String in
//             return a.replace( /[\r\n]+/g, '' );
                return match.replacingMatches(of: "[\r\n]+", with: "")
            })
        }

        // Unmark special paragraph closing tags.
//     html = html.replace( /<\/p#>/g, '</p>\n' );
        output = output.replacingMatches(of: "<\\/p#>", with: "</p>\n")

        // Pad remaining <p> tags whit a line break.
//     html = html.replace( /\s*(<p [^>]+>[\s\S]*?<\/p>)/g, '\n$1' );
        output = output.replacingMatches(of: "\\s*(<p [^>]+>[\\s\\S]*?<\\/p>)", with: "\n$1")

        // Trim.
//     html = html.replace( /^\s+/, '' );
        output = output.replacingMatches(of: "^\\s+", with: "")
//     html = html.replace( /[\s\u00a0]+$/, '' );
        output = output.replacingMatches(of: "[\\s\\u00a0]+$", with: "")

//     if ( preserve_linebreaks ) {
        if preserveLinebreaks {
//         html = html.replace( /<wp-line-break>/g, '\n' );
            output = output.replacingMatches(of: lineBreakMarker, with: "\n")
        }

//     if ( preserve_br ) {
        if preserveBr {
//         html = html.replace( /<wp-temp-br([^>]*)>/g, '<br$1>' );
            output = output.replacingMatches(of: "<wp-temp-br([^>]*)>", with: "<br$1>")
        }

// FIX FIX: Still Needed?
//        // Restore preserved tags.
//        if preserve.count > 0 {
//            output = output.replacingMatches(of: preserveMarker, using: { (_, _) -> String in
//                return preserve.removeFirst()
//            })
//        }

        //                return html;
        return output
    }
}

