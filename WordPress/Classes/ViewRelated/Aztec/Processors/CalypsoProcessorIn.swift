import Foundation
import Aztec


// MARK: - CalypsoProcessorIn
//
class CalypsoProcessorIn: Processor {

    /// Converts a Calypso-Generated string into Valid HTML that can actually be edited by Aztec.
    ///
    /// This method was a direct migration from:
    /// https://github.com/Automattic/wp-calypso/blob/38040768fba5ee8539ebd69204a817f644aa15f3/client/lib/formatting/index.js#L94
    ///
    func process(_ text: String) -> String {

//     const blocklist =
//         'table|thead|tfoot|caption|col|colgroup|tbody|tr|td|th|div|dl|dd|dt|ul|ol|li|pre' +
//         '|form|map|area|blockquote|address|math|style|p|h[1-6]|hr|fieldset|legend|section' +
//         '|article|aside|hgroup|header|footer|nav|figure|figcaption|details|menu|summary';
        let blocklist = "table|thead|tfoot|caption|col|colgroup|tbody|tr|td|th|div|dl|dd|dt|ul|ol|li|pre" +
            "|form|map|area|blockquote|address|math|style|p|h[1-6]|hr|fieldset|legend|section" +
            "|article|aside|hgroup|header|footer|nav|figure|figcaption|details|menu|summary"

//     let preserve_linebreaks = false,
        var preserveLinebreaks = false

//         preserve_br = false;
        var preserveBR = false

        // Normalize line breaks.
        var output = text
        guard output.contains("\n") else {
            return output
        }


        // Remove line breaks from <object>
//     if ( pee.indexOf( '<object' ) !== -1 ) {
        if output.contains("<object") {
//         pee = pee.replace( /<object[\s\S]+?<\/object>/g, function( a ) {
            output = output.replacingMatches(of: "<object[\\s\\S]+?<\\/object>", using: { (match, _) in
//             return a.replace( /[\r\n]+/g, '' );
                return match.replacingMatches(of: "\n+", with: "")
            })
        }

        // Remove line breaks from tags.
//     pee = pee.replace( /<[^<>]+>/g, function( a ) {
        output = output.replacingMatches(of: "<[^<>]+>", using: { (match, _) in
//         return a.replace( /[\r\n]+/g, ' ' );
            return match.replacingMatches(of: "[\r\n]+", with: " ")
        })




        // Preserve line breaks in <pre> and <script> tags.
//     if ( pee.indexOf( '<pre' ) !== -1 || pee.indexOf( '<script' ) !== -1 ) {
        if output.contains("<pre") || output.contains("<script") {
//         preserve_linebreaks = true;
            preserveLinebreaks = true

//         pee = pee.replace( /<(pre|script)[^>]*>[\\s\\S]+?<\\/\\1>/g, function( a ) {
            output = output.replacingMatches(of: "<(pre|script)[^>]*>[\\s\\S]+?<\\/\\1>", using: { (match, _) in
//             return a.replace( /(\r\n|\n)/g, '<wp-line-break>' );
                return match.replacingMatches(of: "(\r\n|\n)", with: "<wp-line-break>")
            })
        }

//        if output.contains("<figcaption") {
//            output = output.replacingMatches(of: "\\s*(<figcaption[^>]*>)", with: "$1")
//            output = output.replacingMatches(of: "</figcaption>\\s*", with: "</figcaption>")
//        }




        // Keep <br> tags inside captions.
//     if ( pee.indexOf( '[caption' ) !== -1 ) {
        if output.contains("[caption") {
//         preserve_br = true;
            preserveBR = true

//         pee = pee.replace( /\[caption[\s\S]+?\[\/caption\]/g, function( a ) {
            output = output.replacingMatches(of: "\\[caption[\\s\\S]+?\\[\\/caption\\]", using: { (match, _) in

//             a = a.replace( /<br([^>]*)>/g, '<wp-temp-br$1>' );
                var updated = match.replacingMatches(of: "<br([^>]*)>", with: "<wp-temp-br$1>")

//             a = a.replace( /<[a-zA-Z0-9]+( [^<>]+)?>/g, function( b ) {
                updated = updated.replacingMatches(of: "<[a-zA-Z0-9]+( [^<>]+)?>", using: { (match, _) in
//                 return b.replace( /[\r\n\t]+/, ' ' );
                    return match.replacingMatches(of: "[\r\n\t]+", with: " ")
                })

//             return a.replace( /\s*\n\s*/g, '<wp-temp-br />' );
                return updated.replacingMatches(of: "\\s*\\n\\s*", with: "<wp-temp-br />")
            })
        }






//     pee = pee + '\n\n';
        output = output + "\n\n"
//     pee = pee.replace( /<br \/>\s*<br \/>/gi, '\n\n' );
        output = output.replacingMatches(of: "<br \\/>\\s*<br \\/>", with: "\n\n", options: .caseInsensitive)

        // Pad block tags with two line breaks.
//     pee = pee.replace( new RegExp( '(<(?:' + blocklist + ')(?: [^>]*)?>)', 'gi' ), '\n$1' );
        output = output.replacingMatches(of: "(<(?:" + blocklist + ")(?: [^>]*)?>)", with: "\n\n$1", options: .caseInsensitive)
//     pee = pee.replace( new RegExp( '(</(?:' + blocklist + ')>)', 'gi' ), '$1\n\n' );
        output = output.replacingMatches(of: "(</(?:" + blocklist + ")>)", with: "$1\n\n", options: .caseInsensitive)
//     pee = pee.replace( /<hr( [^>]*)?>/gi, '<hr$1>\n\n' ); // hr is self closing block element
        output = output.replacingMatches(of: "<hr( [^>]*)?>", with: "<hr$1>\n\n", options: .caseInsensitive)

        // Remove white space chars around <option>.
//     pee = pee.replace( /\s*<option/gi, '<option' ); // No <p> or <br> around <option>
        output = output.replacingMatches(of: "\\s*<option", with: "<option", options: .caseInsensitive)
//     pee = pee.replace( /<\/option>\s*/gi, '</option>' );
        output = output.replacingMatches(of: "<\\/option>\\s*", with: "</option>", options: .caseInsensitive)

        // Normalize multiple line breaks and white space chars.

//     pee = pee.replace( /\r\n|\r/g, '\n' );
        output = text.replacingMatches(of: "\r\n|\r", with: "\n")

//     pee = pee.replace( /\n\s*\n+/g, '\n\n' );
        output = output.replacingMatches(of: "\n\\s*\n+", with: "\n\n")

        // Convert two line breaks to a paragraph.
//     pee = pee.replace( /([\s\S]+?)\n\n/g, '<p>$1</p>\n' );
        output = output.replacingMatches(of: "([\\s\\S]+?)\n\n", with: "<p>$1</p>\n")

        // Remove empty paragraphs.
//     pee = pee.replace( /<p>\s*?<\/p>/gi, '' );
        output = output.replacingMatches(of: "<p>\\s*?<\\/p>", with: "", options: .caseInsensitive)

        // Remove <p> tags that are around block tags.

//         new RegExp( '<p>\\s*(</?(?:' + blocklist + ')(?: [^>]*)?>)\\s*</p>', 'gi' ),
        output = output.replacingMatches(of: "<p>\\s*(</?(?:" + blocklist + ")(?: [^>]*)?>)\\s*</p>", with: "$1", options: .caseInsensitive)
//     pee = pee.replace( /<p>(<li.+?)<\/p>/gi, '$1' );
        output = output.replacingMatches(of: "<p>(<li.+?)<\\/p>", with: "$1", options: .caseInsensitive)

        // Fix <p> in blockquotes.
//     pee = pee.replace( /<p>\s*<blockquote([^>]*)>/gi, '<blockquote$1><p>' );
        output = output.replacingMatches(of: "<p>\\s*<blockquote([^>]*)>", with: "<blockquote$1><p>", options: .caseInsensitive)

//     pee = pee.replace( /<\/blockquote>\s*<\/p>/gi, '</p></blockquote>' );
        output = output.replacingMatches(of: "<\\/blockquote>\\s*<\\/p>", with: "</p></blockquote>", options: .caseInsensitive)

        // Remove <p> tags that are wrapped around block tags.
//     pee = pee.replace( new RegExp( '<p>\\s*(</?(?:' + blocklist + ')(?: [^>]*)?>)', 'gi' ), '$1' );
        output = output.replacingMatches(of: "<p>\\s*(</?(?:" + blocklist + ")(?: [^>]*)?>)", with: "$1", options: .caseInsensitive)


//     pee = pee.replace( new RegExp( '(</?(?:' + blocklist + ')(?: [^>]*)?>)\\s*</p>', 'gi' ), '$1' );
        output = output.replacingMatches(of: "(</?(?:" + blocklist + ")(?: [^>]*)?>)\\s*</p>", with: "$1", options: .caseInsensitive)

//     pee = pee.replace( /\s*\n/gi, '<br />\n' );
        output = output.replacingMatches(of: "\\s*\n", with: "<br />\n")

//     pee = pee.replace( new RegExp( '(</?(?:' + blocklist + ')[^>]*>)\\s*<br />', 'gi' ), '$1' );
        output = output.replacingMatches(of: "(</?(?:" + blocklist + ")[^>]*>)\\s*<br />", with: "$1", options: .caseInsensitive)

//     pee = pee.replace( /<br \/>(\s*<\/?(?:p|li|div|dl|dd|dt|th|pre|td|ul|ol)>)/gi, '$1' );
        output = output.replacingMatches(of: "<br \\/>(\\s*<\\/?(?:p|li|div|dl|dd|dt|th|pre|td|ul|ol)>)", with: "$1", options: .caseInsensitive)

//     pee = pee.replace(
//         /(?:<p>|<br ?\/?>)*\s*\[caption([^\[]+)\[\/caption\]\s*(?:<\/p>|<br ?\/?>)*/gi,
//         '[caption$1[/caption]'
//     );
        output = output.replacingMatches(of: "(?:<p>|<br ?\\/?>)*\\s*\\[caption([^\\[]+)\\[\\/caption\\]\\s*(?:<\\/p>|<br ?\\/?>)*", with: "[caption$1[/caption]", options: .caseInsensitive)


//        output = output.replacingMatches(of: "(<br[^>]*>)\\s*\n", with: "$1", options: .caseInsensitive)




        // Add <br> tags.


        // Remove <br> tags that are around block tags.



        // Remove <p> and <br> around captions.



        // Make sure there is <p> when there is </p> inside block tags that can contain other blocks.
//     pee = pee.replace( /(<(?:div|th|td|form|fieldset|dd)[^>]*>)(.*?)<\/p>/g, function( a, b, c ) {
        output = output.replacingMatches(of: "(<(?:div|th|td|form|fieldset|dd)[^>]*>)(.*?)<\\/p>", using: { (match, submatches) in
//         if ( c.match( /<p( [^>]*)?>/ ) ) {
            guard submatches.count < 2 || submatches[1].matches(regex: "<p( [^>]*)?>").count == 0 else {
                return match
            }

//         return b + '<p>' + c + '</p>';
            return submatches[0] + "<p>" + submatches[1] + "</p>"
        })



        // Restore the line breaks in <pre> and <script> tags.
//     if ( preserve_linebreaks ) {
        if preserveLinebreaks {
//         pee = pee.replace( /<wp-line-break>/g, '\n' );
            output = output.replacingOccurrences(of: "<wp-line-break>", with: "\n")
        }

        // Restore the <br> tags in captions.
//     if ( preserve_br ) {
        if preserveBR {
//         pee = pee.replace( /<wp-temp-br([^>]*)>/g, '<br$1>' );
            output = output.replacingMatches(of: "<wp-temp-br([^>]*)>", with: "<br$1>")
        }

        return output
    }
}

